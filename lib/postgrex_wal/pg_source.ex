defmodule PostgrexWal.PgSource do
  defmodule Util do
    @moduledoc "PgSource auxiliary functions"

    import PostgrexWal.Message
    alias PostgrexWal.{Message, PgSource, StreamBoundaryError}

    @stream_start_key Message.__stream_start_key__()
    @stream_stop_key Message.__stream_stop_key__()
    @streamable_keys Message.__streamable_keys__()

    @doc """
    The logical replication protocol sends individual transactions one by one.
    This means that all messages between a pair of Begin and Commit messages belong to the same transaction.
    It also sends changes of large in-progress transactions between a pair of Stream Start and Stream Stop messages.
    The last stream of such a transaction contains Stream Commit or Stream Abort message.
    """

    @type state() :: PgSource.t()
    @spec decode_wal(Message.event(), state()) :: {Message.t(), state()}
    def decode_wal(<<@stream_start_key, _rest::binary>> = event, state) do
      if state.in_stream?, do: raise(StreamBoundaryError, "adjacent true")
      {decode(event), %{state | in_stream?: true}}
    end

    def decode_wal(<<@stream_stop_key, _rest::binary>> = event, state) do
      unless state.in_stream?, do: raise(StreamBoundaryError, "adjacent false")
      {decode(event), %{state | in_stream?: false}}
    end

    def decode_wal(<<key, transaction_id::32, rest::binary>>, %{in_stream?: true} = state)
        when key in @streamable_keys do
      {
        decode(<<key>> <> rest) |> struct!(transaction_id: transaction_id),
        state
      }
    end

    def decode_wal(event, state), do: {decode(event), state}
  end

  @moduledoc """
  A data-souce (pg replication events) which a GenStage producer could continuously ingest events from.
  """

  alias Postgrex, as: P
  alias Postgrex.ReplicationConnection, as: PR

  use PR, restart: :permanent, shutdown: 10_000
  use TypedStruct
  require Logger

  @typep step() :: :disconnected | :streaming
  typedstruct enforce: true do
    @typedoc "PgSource's state"
    field :publication_name, String.t()
    field :slot_name, String.t()
    field :subscriber, Process.dest()
    field :max_lsn, integer(), default: 0
    field :step, step(), default: :disconnected
    field :in_stream?, boolean(), default: false
  end

  @typep opts() :: [
           {:publication_name, String.t()},
           {:slot_name, String.t()},
           {:subscriber, Process.dest()},
           {:name, GenServer.name()},
           {:hostname, String.t()},
           {:port, String.t()},
           {:database, String.t()},
           {:username, String.t()},
           {:password, String.t()}
         ]
  @spec start_link(opts()) :: {:ok, pid()} | {:error, P.Error.t() | term()}
  def start_link(opts) do
    {init_opts, opts} = Keyword.split(opts, [:publication_name, :slot_name, :subscriber])

    PR.start_link(
      __MODULE__,
      struct!(__MODULE__, init_opts),
      opts ++ [auto_reconnect: true]
    )
  end

  @spec ack(PR.server(), String.t() | non_neg_integer()) :: :ok
  def ack(server, lsn) when is_binary(lsn) do
    {:ok, lsn} = PR.decode_lsn(lsn)
    PR.call(server, {:ack, lsn})
  end

  def ack(server, lsn) when is_integer(lsn) do
    PR.call(server, {:ack, lsn})
  end

  # Callbacks

  @impl true
  def init(state) do
    Logger.debug("pg_source init...")
    {:ok, state}
  end

  @doc """
  Replication slots provide an automated way to ensure that the primary does not remove WAL segments until
  they have been received by all standbys, and that the primary does not remove rows which could cause a recovery
  conflict even when the standby is disconnected.
  """

  @max_messages 10_000
  @impl true
  def handle_connect(%{slot_name: s, publication_name: p} = state) do
    {
      :stream,
      "START_REPLICATION SLOT #{s} LOGICAL 0/0 (proto_version '2', publication_names '#{p}')",
      [max_messages: @max_messages],
      %{state | step: :streaming}
    }
  end

  @doc """
  XLogData (B)
  Byte1('w')
  Identifies the message as WAL data.

  Int64
  The starting point of the WAL data in this message.

  Int64
  The current end of WAL on the server.

  Int64
  The server's system clock at the time of transmission, as microseconds since midnight on 2000-01-01.

  Byten
  A section of the WAL data stream.

  A single WAL record is never split across two XLogData messages. When a WAL record crosses a WAL page boundary, and is therefore already split using continuation records, it can be split at the page boundary. In other words, the first main WAL record and its continuation records can be sent in different XLogData messages.


  Primary keepalive message (B)
  Byte1('k')
  Identifies the message as a sender keepalive.

  Int64
  The current end of WAL on the server.

  Int64
  The server's system clock at the time of transmission, as microseconds since midnight on 2000-01-01.

  Byte1
  1 means that the client should reply to this message as soon as possible, to avoid a timeout disconnect. 0 otherwise.


  Standby status update (F)
  The receiving process can send replies back to the sender at any time, using one of the following message formats (also in the payload of a CopyData message):
  Byte1('r')
  Identifies the message as a receiver status update.

  Int64
  The location of the last WAL byte + 1 received and written to disk in the standby.

  Int64
  The location of the last WAL byte + 1 flushed to disk in the standby.

  Int64
  The location of the last WAL byte + 1 applied in the standby.

  Int64
  The client's system clock at the time of transmission, as microseconds since midnight on 2000-01-01.

  Byte1
  If 1, the client requests the server to reply to this message immediately. This can be used to ping the server, to test if the connection is still healthy.
  """

  @impl true
  def handle_data(<<?w, _wal_start::64, _wal_end::64, _clock::64, payload::binary>>, state) do
    {message, state} = Util.decode_wal(payload, state)
    GenServer.call(state.subscriber, {:message, message})
    {:noreply, state}
  end

  def handle_data(<<?k, _wal_end::64, _clock::64, 0>>, state) do
    {:noreply, [], state}
  end

  def handle_data(<<?k, _wal_end::64, _clock::64, 1>>, state) do
    {:noreply, [ack_message(state.max_lsn)], state}
  end

  def handle_data(data, state) do
    Logger.info("handle_data/2 unknown data: #{inspect(data)}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:ack, lsn}, from, %{max_lsn: max_lsn} = state) when lsn > max_lsn do
    PR.reply(from, :ok)
    Logger.debug("pg_source ack: #{lsn}")
    {:noreply, [ack_message(lsn)], %{state | max_lsn: lsn}}
  end

  def handle_call({:ack, _lsn}, from, state) do
    PR.reply(from, :ok)
    {:noreply, state}
  end

  defp ack_message(lsn) when is_integer(lsn) do
    <<?r, lsn + 1::64, lsn + 1::64, lsn + 1::64, current_time()::64, 0>>
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time, do: System.os_time(:microsecond) - @epoch
end
