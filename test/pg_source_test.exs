defmodule PgSourceTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.{PgSource, PgSourceRelayer, PSQL}
  alias PostgrexWal.Messages.{Begin, Commit, Insert}

  setup_all do
    n = :rand.uniform(100_000)
    slot_name = "slot_#{n}"
    publication_name = "publication_#{n}"
    table_name = "table_#{n}"

    PSQL.cmd("SELECT pg_create_logical_replication_slot('#{slot_name}', 'pgoutput');")
    PSQL.cmd("CREATE PUBLICATION #{publication_name} FOR all tables;")

    sql_test = """
    CREATE TABLE IF NOT EXISTS #{table_name} (a int, b text);
    ALTER TABLE #{table_name} REPLICA IDENTITY FULL;
    """

    PSQL.cmd(sql_test)

    on_exit(fn ->
      PSQL.cmd("SELECT pg_drop_replication_slot('#{slot_name}');")
      PSQL.cmd("DROP PUBLICATION #{publication_name};")
      PSQL.cmd("DROP TABLE #{table_name};")
    end)

    [
      table_name: table_name,
      opts: [
        name: :"pg_source_#{n}",
        publication_name: publication_name,
        slot_name: slot_name,
        database: "postgres",
        username: "postgres"
      ]
    ]
  end

  defp start_repl!(context) do
    start_supervised!({PgSource, context.opts})
    start_supervised!({PgSourceRelayer, {context.opts[:name], self()}})
  end

  defp stop_repl! do
    stop_supervised!(PgSource)
    stop_supervised!(PgSourceRelayer)
  end

  defp restart_repl!(context) do
    stop_repl!()
    start_repl!(context)
  end

  test "pg logical replication ack test", context do
    # shold receive replication events (with consume ack)
    start_repl!(context)
    PSQL.cmd("INSERT INTO #{context.table_name} (a, b) VALUES (1, 'one');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "1", text: "one"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context.opts[:name], lsn)

    PSQL.cmd("INSERT INTO #{context.table_name} (a, b) VALUES (2, 'two');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "2", text: "two"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context.opts[:name], lsn)

    # should not receive any already acked messages
    restart_repl!(context)

    refute_receive [
      %Begin{},
      %Insert{},
      %Commit{}
    ]

    # without ack
    restart_repl!(context)
    PSQL.cmd("INSERT INTO #{context.table_name} (a, b) VALUES (3, 'three');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "3", text: "three"]},
      %Commit{}
    ]

    PSQL.cmd("INSERT INTO #{context.table_name} (a, b) VALUES (4, 'four');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "4", text: "four"]},
      %Commit{}
    ]

    # still can receive un-acked message
    restart_repl!(context)
    PSQL.cmd("INSERT INTO #{context.table_name} (a, b) VALUES (5, 'five');")

    # acked message should not received again
    refute_receive [
      %Begin{},
      %Insert{tuple_data: [text: "1", text: "one"]},
      %Commit{}
    ]

    # acked message should not received again
    refute_receive [
      %Begin{},
      %Insert{tuple_data: [text: "2", text: "two"]},
      %Commit{}
    ]

    # un-acked message should received again
    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "3", text: "three"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context.opts[:name], lsn)

    # un-acked message should received again
    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "4", text: "four"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context.opts[:name], lsn)

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "5", text: "five"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context.opts[:name], lsn)

    restart_repl!(context)
    # due to all acked, should not receive anymore
    refute_receive [
      %Begin{},
      %Insert{},
      %Commit{}
    ]

    stop_repl!()
  end
end
