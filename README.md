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

## Running tests

### Step 1: Clone the repo and fetch its dependencies:

    $ git clone https://github.com/Byzanteam/postgrex_wal.git
    $ cd postgrex_wal
    $ mix deps.get

### Step 2: You need to configure the wal level in PostgreSQL to logical.

Run this inside your PostgreSQL shell/configuration :

      ALTER SYSTEM SET wal_level='logical';
      ALTER SYSTEM SET max_wal_senders='10';
      ALTER SYSTEM SET max_replication_slots='10';

Then **you must restart your server**.

### Step 3: You must create a publication to be replicated.

This can be done in any session:

      CREATE PUBLICATION postgrex_example FOR ALL TABLES;

You can also filter if you want to publish insert, update,
delete or a subset of them:

      # Skips updates (keeps inserts, deletes, begins, commits, etc)
      create PUBLICATION postgrex_example FOR ALL TABLES WITH (publish = 'insert,delete');

      # Skips inserts, updates, and deletes (keeps begins, commits, etc)
      create PUBLICATION postgrex_example FOR ALL TABLES WITH (publish = '');

### Step 4: Setup your environment variables for postgreSQL db connection.

Currently we build pg connection based on following environment variables (with default values).

Setup these environment variables in your test environment as your need.

```elixir
  def pg_env do
    [
      username: System.get_env("PG_USERNAME", "postgres"),
      database: System.get_env("PG_DATABASE", "postgres"),
      host: System.get_env("PG_HOST", "localhost"),
      password: System.get_env("PG_PASSWORD", "postgres"),
      port: System.get_env("PG_PORT", "5432")
    ]
  end

  def database_url do
    e = pg_env()
    "postgres://#{e[:username]}:#{e[:password]}@#{e[:host]}:#{e[:port]}/#{e[:database]}"
  end
```

### Step 5: Run the test.

    $ mix test

## Important links

* [Postgrex.ReplicationConnection](https://hexdocs.pm/postgrex/Postgrex.ReplicationConnection.html)
* [GenStage](https://hexdocs.pm/gen_stage/GenStage.html)
* [Elixir Broadway](https://elixir-broadway.org/)

## License

MIT License
