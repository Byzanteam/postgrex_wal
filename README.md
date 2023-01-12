# PostgrexWal

This project provides:

* `PostgrexWal.PgSource` - A generic behaviour to implement `Postgrex.ReplicationConnection`.
* `PostgrexWal.Message` - The pg replication protocol 2 message decoder module.

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

## Other Info

This library was created using
the [Postgrex.ReplicationConnection behaviour](https://hexdocs.pm/postgrex/Postgrex.ReplicationConnection.html) for
reference.
----

## License

MIT License
