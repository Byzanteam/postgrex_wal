defmodule PostgrexWal.GenStage.PgSource do
  @moduledoc ~S"""
  ## Sample:
  opts = [
    name: :my_pg_source,
    publication_name: "mypub1",
    slot_name: "myslot1"
    conn_opts: [host: "localhost", database: "r704_development", username: "jswk"]
  ]
  """
  use Postgrex.ReplicationConnection, restart: :permanent, shutdown: 10_000
  use TypedStruct
  require Logger

  @typep step() :: :disconnected | :streaming
  typedstruct enforce: true do
    field :publication_name, String.t()
    field :slot_name, String.t()
    field :final_lsn, integer(), default: 0
    field :step, step(), default: :disconnected
  end

  @typep conn_opts() :: [{:host, String.t()}, {:database, String.t()}, {:username, String.t()}]
  @typep opts() :: [
           {:name, String.t()},
           {:publication_name, String.t()},
           {:slot_name, String.t()},
           {:conn_opts, conn_opts()}
         ]
  @spec start_link(opts()) :: {:ok, pid()} | {:error, Postgrex.Error.t() | term()}
  def start_link(opts) do
    # Automatically reconnect if we lose connection.
    extra_opts = [
      auto_reconnect: true,
      name: opts[:name]
    ]

    Postgrex.ReplicationConnection.start_link(
      __MODULE__,
      struct(__MODULE__, Keyword.take(opts, [:publication_name, :slot_name])),
      extra_opts ++ opts[:conn_opts]
    )
  end

  # api functions()

  @spec stop(GenServer.server()) :: :ok
  def stop(server) do
    GenServer.stop(server)
  end

  @type lsn() :: integer() | String.t()
  @spec async_ack(GenServer.server(), lsn()) :: {:ack, lsn()}
  def async_ack(server, lsn) when is_integer(lsn) do
    send(server, {:ack, lsn})
  end

  def async_ack(server, lsn) when is_binary(lsn) do
    {:ok, lsn} = Postgrex.ReplicationConnection.decode_lsn(lsn)
    async_ack(server, lsn)
  end

  # callbacks()

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
    query =
      "START_REPLICATION SLOT #{state.slot_name} LOGICAL 0/0 (proto_version '2', publication_names '#{state.publication_name}')"

    {:stream, query, [], %{state | step: :streaming}}
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
    IO.puts(payload)
    {:noreply, state}
  end

  def handle_data(<<?k, _wal_end::64, _clock::64, reply>>, state) do
    message =
      case reply do
        1 -> ack_message(state.final_lsn)
        0 -> []
      end

    {:noreply, message, state}
  end

  def handle_data(data, state) do
    Logger.error("handle_data/2 Unknown data: #{inspect(data)}")
    {:noreply, state}
  end

  @impl true
  def handle_result(_results, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:ack, lsn}, state) do
    state = if lsn > state.final_lsn, do: %{state | final_lsn: lsn}, else: state
    {:noreply, ack_message(state.fina_lsn), state}
  end

  def handle_info(data, state) do
    Logger.error("handle_info/2 Unknown data: #{inspect(data)}")
    {:noreply, state}
  end

  defp ack_message(lsn) when is_integer(lsn) do
    [<<?r, lsn + 1::64, lsn + 1::64, lsn + 1::64, current_time()::64, 0>>]
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time, do: System.os_time(:microsecond) - @epoch
end
