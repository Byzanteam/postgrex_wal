defmodule PgSourceTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.{PgSource, PgSourceRelayer, PSQL}
  alias PostgrexWal.Messages.{Begin, Commit, Insert}
  alias PostgrexWal.Messages.Insert

  @pg_srouce_opts [
    name: :my_pg_source,
    publication_name: "mypub5",
    slot_name: "myslot5"
  ]

  @pg_conn_opts [
    database: "postgres",
    username: "postgres"
  ]

  setup do
    [
      source:
        start_supervised!(
          {PgSource, @pg_srouce_opts ++ @pg_conn_opts},
          id: :source
        ),
      relayer:
        start_supervised!(
          {PgSourceRelayer, {:my_pg_source, self()}},
          id: :relayer
        )
    ]
  end

  test "shold receive replication events with ack", context do
    PSQL.cmd("INSERT INTO users (a, b) VALUES (1, 'one');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "1", text: "one"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context[:source], lsn)

    PSQL.cmd("INSERT INTO users (a, b) VALUES (2, 'two');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "2", text: "two"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context[:source], lsn)
  end

  test "without ack" do
    PSQL.cmd("INSERT INTO users (a, b) VALUES (3, 'three');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "3", text: "three"]},
      %Commit{}
    ]

    PSQL.cmd("INSERT INTO users (a, b) VALUES (4, 'four');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "4", text: "four"]},
      %Commit{}
    ]
  end

  test "still receive un-acked message", context do
    PSQL.cmd("INSERT INTO users (a, b) VALUES (5, 'five');")

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "3", text: "three"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context[:source], lsn)

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "4", text: "four"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context[:source], lsn)

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "5", text: "five"]},
      %Commit{end_lsn: lsn}
    ]

    PgSource.ack(context[:source], lsn)
  end
end
