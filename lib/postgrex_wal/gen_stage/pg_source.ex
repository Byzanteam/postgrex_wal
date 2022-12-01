defmodule PostgrexWal.GenStage.PgSource do
  use Postgrex.ReplicationConnection
  @publication_name "postgrex_example"

  def start_link(pg_conn_opts) do
    # Automatically reconnect if we lose connection.
    extra_opts = [
      auto_reconnect: true,
      name: __MODULE__
    ]

    Postgrex.ReplicationConnection.start_link(__MODULE__, :ok, extra_opts ++ pg_conn_opts)
  end

  @impl true
  def init(:ok) do
    {:ok, %{step: :disconnected}}
  end

  @impl true
  def handle_connect(state) do
    query = "CREATE_REPLICATION_SLOT postgrex TEMPORARY LOGICAL pgoutput NOEXPORT_SNAPSHOT"
    {:query, query, %{state | step: :create_slot}}
  end

  @impl true
  def handle_result(results, %{step: :create_slot} = state) when is_list(results) do
    query = "START_REPLICATION SLOT postgrex LOGICAL 0/0 (proto_version '1', publication_names '#{@publication_name}')"
    {:stream, query, [], %{state | step: :streaming}}
  end

  @impl true
  def handle_data(<<?w, _wal_start::64, _wal_end::64, _clock::64, rest::binary>>, state) do
    PostgrexWal.GenStage.PgSourceRelayer.async_notify(rest)
    {:noreply, state}
  end

  # keep-alive msg
  def handle_data(<<?k, wal_end::64, _clock::64, reply>>, state) do
    messages =
      case reply do
        1 -> [<<?r, wal_end + 1::64, wal_end + 1::64, wal_end + 1::64, current_time()::64, 0>>]
        0 -> []
      end

    {:noreply, messages, state}
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time(), do: System.os_time(:microsecond) - @epoch
end
