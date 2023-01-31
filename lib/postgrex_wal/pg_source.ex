defmodule PostgrexWal.PgSource do
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
    field :publication_name, String.t()
    field :slot_name, String.t()
    field :max_lsn, integer(), default: 0
    field :step, step(), default: :disconnected
    field :subscriber, pid(), default: nil
    field :events, list(), default: []
  end

  @typep opts() :: [
           {:name, GenServer.name()},
           {:publication_name, String.t()},
           {:slot_name, String.t()},
           {:host, String.t()},
           {:port, String.t()},
           {:database, String.t()},
           {:username, String.t()},
           {:password, String.t()},
           {:subscriber, pid()}
         ]
  @spec start_link(opts()) :: {:ok, pid()} | {:error, P.Error.t() | term()}
  def start_link(opts) do
    {init_opts, opts} = Keyword.split(opts, [:publication_name, :slot_name, :subscriber])

    PR.start_link(
      __MODULE__,
      struct(__MODULE__, init_opts),
      opts ++ [auto_reconnect: true]
    )
  end

  @spec ack(PR.server(), String.t()) :: :ok
  def ack(server, lsn) when is_binary(lsn) do
    {:ok, lsn} = PR.decode_lsn(lsn)
    PR.call(server, {:ack, lsn})
  end

  @spec subscribe(PR.server()) :: :ok
  def subscribe(server) do
    PR.call(server, :subscribe)
  end

  # Callbacks

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Replication slots provide an automated way to ensure that the primary does not remove WAL segments until
  they have been received by all standbys, and that the primary does not remove rows which could cause a recovery
  conflict even when the standby is disconnected.
  """

  @impl true
  def handle_connect(state) do
    {
      :stream,
      "START_REPLICATION SLOT #{state.slot_name} LOGICAL 0/0 (proto_version '2', publication_names '#{state.publication_name}')",
      [],
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
  # _::192 composed of _wal_start::64, _wal_end::64, _clock::64
  def handle_data(<<?w, _::192, payload::binary>>, %{subscriber: nil} = state) do
    {:noreply, %{state | events: [payload | state.events]}}
  end

  def handle_data(<<?w, _::192, payload::binary>>, state) do
    send(state.subscriber, {:events, Enum.reverse([payload | state.events])})
    {:noreply, %{state | events: []}}
  end

  def handle_data(<<?k, _wal_end::64, _clock::64, reply>>, state) do
    messages =
      case reply do
        1 -> [ack_message(state.max_lsn)]
        0 -> []
      end

    {:noreply, messages, state}
  end

  def handle_data(data, state) do
    Logger.warning("handle_data/2 unknown data: #{inspect(data)}")
    {:noreply, state}
  end

  @impl true
  def handle_call(:subscribe, from, state) do
    {pid, _} = from
    Process.monitor(pid)
    PR.reply(from, :ok)
    {:noreply, %{state | subscriber: pid}}
  end

  def handle_call({:ack, lsn}, from, %{max_lsn: max_lsn} = state) when lsn > max_lsn do
    PR.reply(from, :ok)
    state = %{state | max_lsn: lsn}
    Logger.debug("pg_source ack: #{lsn}")
    {:noreply, [ack_message(lsn)], state}
  end

  def handle_call({:ack, _lsn}, from, state) do
    PR.reply(from, :ok)
    {:noreply, [], state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, %{subscriber: pid} = state) do
    {:noreply, %{state | subscriber: nil}}
  end

  def handle_info(data, state) do
    Logger.warning("handle_info/2 unknown data: #{inspect(data)}")
    {:noreply, state}
  end

  defp ack_message(lsn) when is_integer(lsn) do
    <<?r, lsn + 1::64, lsn + 1::64, lsn + 1::64, current_time()::64, 0>>
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time, do: System.os_time(:microsecond) - @epoch
end
