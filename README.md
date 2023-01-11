# PostgrexWal

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `postgrex_wal` to your list of dependencies in `mix.exs`:

# PostgrexWal

This project provides:

* `PostgrexWal.Producer` - A GenStage producer that continuously ingest events from a pg_replication and acknowledges
  them after being successfully processed.
* `PostgrexWal.PgSource` - A generic behaviour to implement `Postgrex.ReplicationConnection`.
* `PostgrexWal.Message` - The pg replication protocol 2 message decode entry module.

## Installation

Add `:postgrex_wal` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:postgrex_wal, "~> 0.1.0"}
  ]
end
```

## Usage

Configure Broadway with one or more producers using `PostgrexWal.Producer`:

```elixir
defmodule MyBroadway do
  @moduledoc false
  use Broadway
  require Logger

  @doc """
  ## Example
  
  opts = [
    name: PostgrexWal.PgSource,
    publication_name: "my_pub",
    slot_name: "my_slot",
    database: "postgres",
    username: "postgres"
  ]

    MyBroadway.start_link(opts)
  """

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {PostgrexWal.Producer, opts},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ]
    )
  end

  def handle_message(_, message, _) do
    message
  end
end
```

----

## Other Info

This library was created using
the [Broadway Custom Producers documentation](https://hexdocs.pm/broadway/custom-producers.html) for reference. I would
encourage you to view that as well as
the [Broadway Architecture documentation](https://hexdocs.pm/broadway/architecture.html) for more information.

----

## License

MIT License

See the [license file](LICENSE.txt) for details.
