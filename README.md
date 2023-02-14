# PostgrexWal

[![Elixir CI](https://github.com/Byzanteam/postgrex_wal/actions/workflows/elixir.yml/badge.svg)](https://github.com/Byzanteam/postgrex_wal/actions/workflows/elixir.yml)

A `GenStage` producer for `Broadway` that continuously ingest events from a Postgrex.ReplicationConnection.

This project provides:

* `PostgrexWal.PgSource` - A generic behaviour to implement `Postgrex.ReplicationConnection`.
* `PostgrexWal.Message` - The postgreSQL replication protocol 2 message decoder module.

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

## Usage

Configure Broadway with one or more producers using `PostgrexWal.PgProducer`:

```elixir
  defmodule MyBroadway do
    use Broadway
  
    def start_link(_opts) do
      Broadway.start_link(__MODULE__,
        name: __MODULE__,
        producer: [
          module: {
            PostgrexWal.PgProducer,
            name: :my_pg_source,
            publication_name: "your_pub",
            slot_name: "your_slot",
            username: "your_username",
            database: "your_db",
            password: "your_pass",
            hostname: "localhost",
            port: "5432"
          },
          concurrency: 1
        ],
        processors: [
          default: [
            max_demand: 1_000, 
            min_demand: 500, 
            concurrency: 1
          ]
        ]
      )
    end
  
    @impl true
    def handle_message(_processor_name, message, _context) do
      message |> IO.inspect(label: "Got message")
    end
  end
```

## Limits

* Because the logical replication only replicates the DML, changes to the DDL do not appear in the message.
* Logical replication does not deliver the `Tosted value`, so the Tosted value can only be identified as "toast" in the
  decoded message, and the actual value is not in the message.

## Running tests

### Step 1: You need to configure the wal level in PostgreSQL to logical.

Run this inside your PostgreSQL shell/configuration :

      ALTER SYSTEM SET wal_level='logical';
      ALTER SYSTEM SET max_wal_senders='10';
      ALTER SYSTEM SET max_replication_slots='10';

Then **you must restart your server**. Alternatively, you can set
those values when starting "postgres". This is useful, for example,
when running it from Docker:

      services:
        postgres:
          image: postgres:14
          env:
            ...
          command: ["postgres", "-c", "wal_level=logical"]

### Step 2: Setup your environment variables for postgreSQL connection.

Currently we build postgreSQL connection based on following environment variables (with default values).
Setup these environment variables in your test environment as you need.

Please note that the user **must be a replication role**.

```elixir
  def pg_env do
    [
      hostname: System.get_env("PG_HOST", "localhost"),
      port: System.get_env("PG_PORT", "5432"),
      database: System.get_env("PG_DATABASE", "postgres"),
      username: System.get_env("PG_USERNAME", "postgres"),
      password: System.get_env("PG_PASSWORD", "postgres")
    ]
  end

  def database_url do
    e = pg_env()
    "postgres://#{e[:username]}:#{e[:password]}@#{e[:hostname]}:#{e[:port]}/#{e[:database]}"
  end
```

### Step 3: Clone the repo and fetch its dependencies:

    $ git clone https://github.com/Byzanteam/postgrex_wal.git
    $ cd postgrex_wal
    $ mix deps.get
    $ mix test

## Reference links

* [Postgrex.ReplicationConnection](https://hexdocs.pm/postgrex/Postgrex.ReplicationConnection.html)
* [GenStage](https://hexdocs.pm/gen_stage/GenStage.html)
* [Elixir Broadway](https://elixir-broadway.org/)

## License

MIT License
