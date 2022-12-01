# PostgrexWal

GenStage-compliant Producer, emit replication events from Postgresql.

## Prerequisite
1. echo "wal_level=logical" >> /var/lib/postgresql/data/postgresql.conf'
2. ALTER SYSTEM SET wal_level = 'logical';
3. CREATE PUBLICATION postgrex_example FOR ALL TABLES;

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `postgrex_wal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:postgrex_wal, "~> 0.1.0"}
  ]
end
```
and run `$ mix deps.get`. 

## Usage

```elixir
iex> pg_conn_opts = [host: "your pg_host", database: "your pg_database", username: "your pg_username"]
iex> PostgrexWal.start_link(pg_conn_opts)
```
## FYI

1. Start the producer as above.The Producer(source) local-register name:  `PostgrexWal.GenStage.Producer`
2. Start your consumer, and make your consumer `subscribe_to: [PostgrexWal.GenStage.Producer]`
3. The Replication events would down-stream to your consumer just-in-time.
4. In your project, you can put `{PostgrexWal.GenStage.Producer, pg_conn_opts}` as a child under your Supervision tree to auto-start before your consumer.
5. `mix test --seed 0` passed.

```elixir
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

```
## License
    Copyright © 2022-present
