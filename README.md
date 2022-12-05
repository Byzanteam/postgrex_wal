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
iex> pg_conn_opts = [host: "your_pg_host", database: "your_pg_database", username: "your_pg_username"]
iex> opts = [
        publication_name: "your_publication_name", 
        producer_name: "assigned producer name",
        pg_conn_opts: pg_conn_opts
    ] 
iex> PostgrexWal.start_link(opts)
```
## FYI

1.  In your project, you can inject `{PostgrexWal, opts}` as a child-spec into your Supervision tree to auto-start before your consumer.
2. Start your consumer, and make your consumer `subscribe_to: ["assigned producer name"]`
3. The Replication events would down-stream to your consumer just-in-time.
4. `mix test --seed 0` passed.

## Transaction events sample(Insert, Update, Delete)

`INSERT INTO users (name, age) VALUES ('abc', 22) `
```elixir

[
  %PgoutputDecoder.Messages.Begin{
    final_lsn: {0, 48156952},
    commit_timestamp: ~U[2022-12-02 01:28:02Z],
    xid: 3403
  },
  %PgoutputDecoder.Messages.Relation{
    id: 22887,
    namespace: "public",
    name: "users",
    replica_identity: :default,
    columns: [
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [:key],
        name: "id",
        type: :int8,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "name",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "age",
        type: :int4,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "email",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "password_digest",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "salary",
        type: :unknown,
        type_modifier: 393222
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "sex",
        type: :bool,
        type_modifier: 4294967295
      }
    ]
  },
  %PgoutputDecoder.Messages.Insert{
    relation_id: 22887,
    tuple_data: {"980191166", "abc", "21", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Commit{
    flags: [],
    lsn: {0, 48156952},
    end_lsn: {0, 48157000},
    commit_timestamp: ~U[2022-12-02 01:28:02Z]
  }
]
```

`UPDATE users SET age = 23 WHERE name = 'abc'` 
```elixir
[
  %PgoutputDecoder.Messages.Begin{
    final_lsn: {0, 48207232},
    commit_timestamp: ~U[2022-12-02 02:05:48Z],
    xid: 3413
  },
  %PgoutputDecoder.Messages.Relation{
    id: 22887,
    namespace: "public",
    name: "users",
    replica_identity: :default,
    columns: [
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [:key],
        name: "id",
        type: :int8,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "name",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "age",
        type: :int4,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "email",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "password_digest",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "salary",
        type: :unknown,
        type_modifier: 393222
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "sex",
        type: :bool,
        type_modifier: 4294967295
      }
    ]
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191166", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191167", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191168", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191169", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191170", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191171", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191172", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191173", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Update{
    relation_id: 22887,
    changed_key_tuple_data: nil,
    old_tuple_data: nil,
    tuple_data: {"980191174", "abc", "23", nil, nil, nil, nil}
  },
  %PgoutputDecoder.Messages.Commit{
    flags: [],
    lsn: {0, 48207232},
    end_lsn: {0, 48207280},
    commit_timestamp: ~U[2022-12-02 02:05:48Z]
  }
]
```
`DELETE FROM users WHERE name = 'abc'`

```elixir
[
  %PgoutputDecoder.Messages.Begin{
    final_lsn: {0, 48208112},
    commit_timestamp: ~U[2022-12-02 02:06:17Z],
    xid: 3414
  },
  %PgoutputDecoder.Messages.Relation{
    id: 22887,
    namespace: "public",
    name: "users",
    replica_identity: :default,
    columns: [
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [:key],
        name: "id",
        type: :int8,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "name",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "age",
        type: :int4,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "email",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "password_digest",
        type: :varchar,
        type_modifier: 4294967295
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "salary",
        type: :unknown,
        type_modifier: 393222
      },
      %PgoutputDecoder.Messages.Relation.Column{
        flags: [],
        name: "sex",
        type: :bool,
        type_modifier: 4294967295
      }
    ]
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191166", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191167", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191168", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191169", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191170", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191171", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191172", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191173", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Delete{
    relation_id: 22887,
    changed_key_tuple_data: {"980191174", nil, nil, nil, nil, nil, nil},
    old_tuple_data: nil
  },
  %PgoutputDecoder.Messages.Commit{
    flags: [],
    lsn: {0, 48208112},
    end_lsn: {0, 48208160},
    commit_timestamp: ~U[2022-12-02 02:06:17Z]
  }
]
```

## License
    Copyright © 2022-present
