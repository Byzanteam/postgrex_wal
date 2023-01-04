defmodule PostgrexWal.PgSource do
  @moduledoc false

  alias Postgrex, as: P
  alias Postgrex.ReplicationConnection, as: PR

  use PR, restart: :permanent, shutdown: 10_000
  use TypedStruct
  require Logger

  @typep step() :: :disconnected | :streaming
  @typep queue(type) :: :queue.queue(type)
  typedstruct enforce: true do
    field :publication_name, String.t()
    field :slot_name, String.t()
    field :final_lsn, integer(), default: 0
    field :step, step(), default: :disconnected
    field :subscribers, MapSet.t(pid), default: MapSet.new()
    field :queue, queue(struct()), default: :queue.new()
    field :size, integer, default: 0
  end

  @doc ~S"""
  ## 调用参数示例
   opts = [
     name: :my_pg_source,
     publication_name: "mypub1",
     slot_name: "myslot1",
     host: "localhost",
     database: "r704_development",
     username: "jswk"
   ]
  """

  @typep opts() :: [
           {:name, GenServer.name()},
           {:publication_name, String.t()},
           {:slot_name, String.t()},
           {:host, String.t()},
           {:database, String.t()},
           {:username, String.t()}
         ]
  @spec start_link(opts()) :: {:ok, pid()} | {:error, P.Error.t() | term()}
  def start_link(opts) do
    {init_opts, opts} = Keyword.split(opts, [:publication_name, :slot_name])

    PR.start_link(
      __MODULE__,
      struct(__MODULE__, init_opts),
      opts ++ [auto_reconnect: true]
    )
  end

  @spec ack(PR.server(), String.t()) :: {:ack, integer}
  def ack(server, lsn) when is_binary(lsn) do
    {:ok, lsn} = PR.decode_lsn(lsn)
    send(server, {:ack, lsn})
  end

  @spec subscribe(PR.server()) :: {:subscribe, pid()}
  def subscribe(server) do
    send(server, {:subscribe, self()})
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
      [max_messages: 500],
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
    state = %{state | queue: :queue.in(payload, state.queue), size: state.size + 1}

    # Behaviour maybe changed when introduce Broadway.
    if MapSet.size(state.subscribers) > 0 do
      events = :queue.to_list(state.queue)
      for s <- state.subscribers, do: send(s, {:events, events})
      {:noreply, %{state | queue: :queue.new(), size: 0}}
    else
      {:noreply, state}
    end
  end

  def handle_data(<<?k, _wal_end::64, _clock::64, reply>>, state) do
    messages =
      case reply do
        1 -> [ack_message(state.final_lsn)]
        0 -> []
      end

    {:noreply, messages, state}
  end

  def handle_data(data, state) do
    Logger.warning("handle_data/2 unknown data: #{inspect(data)}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:ack, lsn}, state) do
    state = if lsn > state.final_lsn, do: %{state | final_lsn: lsn}, else: state
    {:noreply, [ack_message(state.final_lsn)], state}
  end

  def handle_info({:subscribe, pid}, state) do
    Process.monitor(pid)

    {
      :noreply,
      %{state | subscribers: state.subscribers |> MapSet.put(pid)}
    }
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {
      :noreply,
      %{state | subscribers: state.subscribers |> MapSet.delete(pid)}
    }
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