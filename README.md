# PostgrexWal

**TODO: Add description**

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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/postgrex_wal>.

```elixir
defmodule Repl do
  use Postgrex.ReplicationConnection

  def start_link(opts) do
    # Automatically reconnect if we lose connection.
    extra_opts = [
      auto_reconnect: true
    ]

    Postgrex.ReplicationConnection.start_link(__MODULE__, :ok, extra_opts ++ opts)
  end

  @impl true
  def init(:ok) do
    {:ok, %{step: :disconnected}}
  end

  @impl true
  def handle_connect(%{step: :streaming} = state) do
    {:noreply, state}
  end

  def handle_connect(%{step: :disconnected} = state) do
    query = "CREATE_REPLICATION_SLOT postgrex LOGICAL pgoutput NOEXPORT_SNAPSHOT"
    {:query, query, %{state | step: :create_slot}}
  end

  @impl true
  def handle_result(results, %{step: :create_slot} = state) when is_list(results) do
    query =
      "START_REPLICATION SLOT postgrex LOGICAL 0/0 (proto_version '1', publication_names 'example')"

    {:stream, query, [], %{state | step: :streaming}}
  end

  def handle_result(results, state) do
    IO.inspect(results, label: :results)
    {:noreply, state}
  end

  @impl true
  # https://www.postgresql.org/docs/14/protocol-replication.html
  def handle_data(<<?w, _wal_start::64, _wal_end::64, _clock::64, rest::binary>>, state) do
    PostgrexWal.Message.decode(rest) |> IO.inspect()

    {:noreply, state}
  end

  def handle_data(<<?k, wal_end::64, _clock::64, reply>>, state) do
    messages =
      case reply do
        1 -> [<<?r, wal_end + 1::64, wal_end + 1::64, wal_end + 1::64, current_time()::64, 0>>]
        0 -> []
      end

    {:noreply, messages, state}
  end

  def handle_data(data, state) do
    IO.inspect(data, label: :data)
    {:noreply, state}
  end

  @epoch DateTime.to_unix(~U[2000-01-01 00:00:00Z], :microsecond)
  defp current_time(), do: System.os_time(:microsecond) - @epoch
end

{:ok, pid} =
  Repl.start_link(
    host: "localhost",
    database: "postgres",
    username: "postgres",
    password: "postgres"
  )
```
