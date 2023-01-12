# PostgrexWal

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `postgrex_wal` to your list of dependencies in `mix.exs`:

# PostgrexWal

This project provides:

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

## Other Info

This library was created using
the [Broadway Custom Producers documentation](https://hexdocs.pm/broadway/custom-producers.html) for reference. We would
encourage you to view that as well as
the [Broadway Architecture documentation](https://hexdocs.pm/broadway/architecture.html) for more information.

----

## License

MIT License
