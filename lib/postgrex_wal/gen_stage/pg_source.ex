defmodule PostgrexWal.GenStage.PgSource do
  @moduledoc false
  use Postgrex.ReplicationConnection, restart: :permanent, shutdown: 10_000

  def start_link(_pg_source_opts \\ []) do
    # Automatically reconnect if we lose connection.

    extra_opts = [
      auto_reconnect: true,
      name: __MODULE__
    ]

    pg_source_opts = [
      # producer_name: :my_prod,
      publication_name: "mypub1",
      conn_opts: [
        host: "localhost",
        database: "r704_development",
        username: "jswk"
      ]
    ]

    Postgrex.ReplicationConnection.start_link(
      __MODULE__,
      pg_source_opts[:publication_name],
      extra_opts ++ pg_source_opts[:conn_opts]
    )
  end

  # functions()

  @type wal() :: integer() | String.t()
  @spec async_ack(wal()) :: {:ack, wal()}
  def async_ack(wal) when is_integer(wal) do
    send(__MODULE__, {:ack, wal})
  end

  def async_ack(wal) when is_binary(wal) do
    async_ack(encode_lsn(wal))
  end

  @spec encode_lsn(lsn :: String.t()) :: integer
  defp encode_lsn(lsn) when is_binary(lsn) do
    [xlog_file_id, xlog_offset] = String.split(lsn, "/", trim: true)

    <<lsn::64>> =
      <<String.to_integer(xlog_file_id, 16)::32, String.to_integer(xlog_offset, 16)::32>>

    lsn
  end

  # callbacks()

  @impl true
  def init(pub_name) do
    {:ok, %{step: :disconnected, pub_name: pub_name, in_transaction: false, wal: 0}}
  end

  @doc """
  Replication slots provide an automated way to ensure that the primary does not remove WAL segments until
  they have been received by all standbys, and that the primary does not remove rows which could cause a recovery
  conflict even when the standby is disconnected.
  """
  @impl true
  def handle_connect(state) do
    query =
      "START_REPLICATION SLOT myslot1 LOGICAL 0/0 (proto_version '2', publication_names '#{state.pub_name}')"

    {:stream, query, [], %{state | step: :streaming}}
  end

  #  @doc """
  #  Logical Streaming Replication Protocol
  #  https://www.postgresql.org/docs/15/protocol-logical-replication.html
  #
  #  Protocol version. Currently versions 1, 2, and 3 are supported.
  #  Version 2 is supported only for server version 14 and above, and it allows streaming of large in-progress
  # transactions.
  #  Version 3 is supported only for server version 15 and above, and it allows streaming of two-phase commits.
  #  """
  #  @impl true
  #  def handle_result(results, %{step: :create_slot} = state) when is_list(results) do
  #    query =
  #      "START_REPLICATION SLOT postgrex LOGICAL 0/0 (proto_version '2', publication_names '#{state.pub_name}')"
  #
  #    {:stream, query, [], %{state | step: :streaming}}
  #  end

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

  @modules %{
    ?A => StreamAbort,
    ?B => Begin,
    ?C => Commit,
    ?D => Delete,
    ?E => StreamStop,
    ?I => Insert,
    ?M => Message,
    ?O => Origin,
    ?R => Relation,
    ?S => StreamStart,
    ?T => Truncate,
    ?U => Update,
    ?Y => Type,
    ?c => StreamCommit
  }

  @impl true
  def handle_data(<<?w, _wal_start::64, _wal_end::64, _clock::64, payload::binary>>, state) do
    <<key::8, _rest::binary>> = payload

    state =
      case key do
        ?S -> %{state | in_transaction: true}
        v when v in [?E, ?c, ?A] -> %{state | in_transaction: false}
        _ -> state
      end

    event =
      if key in [?I, ?D, ?M, ?R, ?T, ?Y, ?U] and state[:in_transaction] do
        {:in_transaction, payload}
      else
        payload
      end

    IO.puts("message: #{@modules[key]}")
    event |> PostgrexWal.Message.decode() |> IO.puts()

    # IO.inspect(@modules[key], label: "message")
    # event |> IO.inspect(limit: :infinity) |> PostgrexWal.Message.decode() |> IO.inspect()

    # PostgrexWal.GenStage.PgSourceRelayer.async_notify(rest)
    {:noreply, state}
  end

  def handle_data(<<?k, _wal_end::64, _clock::64, reply>>, state) do
    messages =
      case reply do
        1 -> ack_messages(state[:wal])
        0 -> []
      end

    {:noreply, messages, state}
  end

  @impl true
  def handle_info({:ack, wal}, state) do
    state = (wal > state[:wal] && %{state | wal: wal}) || state
    {:noreply, ack_messages(state[:wal]), state}
  end

  defp ack_messages(wal) when is_integer(wal) do
    [<<?r, wal + 1::64, wal + 1::64, wal + 1::64, current_time()::64, 0>>]
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time, do: System.os_time(:microsecond) - @epoch
end
