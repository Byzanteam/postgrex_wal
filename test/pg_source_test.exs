defmodule PgSourceTest do
  use ExUnit.Case, async: true

  alias PostgrexWal.{PgSource, PgSourceRelayer, PSQL}
  alias PostgrexWal.Messages.{Begin, Commit, Insert}

  setup context do
    case_id = case_identity(context)

    slot_name = "slot_#{case_id}"
    publication_name = "publication_#{case_id}"
    table_name = "users_#{case_id}"

    PSQL.cmd([
      "CREATE TABLE #{table_name} (id bigint);",
      "ALTER TABLE #{table_name} REPLICA IDENTITY FULL;",
      "SELECT pg_create_logical_replication_slot('#{slot_name}', 'pgoutput');",
      "CREATE PUBLICATION #{publication_name} FOR TABLE #{table_name};"
    ])

    on_exit(fn ->
      PSQL.cmd([
        "SELECT pg_drop_replication_slot('#{slot_name}');",
        "DROP PUBLICATION #{publication_name};",
        "DROP TABLE #{table_name};"
      ])
    end)

    [
      table_name: table_name,
      opts: [
        publication_name: publication_name,
        slot_name: slot_name,
        database: System.get_env("WAL_DB", "postgres"),
        host: System.get_env("WAL_HOST", "localhost"),
        username: System.get_env("WAL_USERNAME", "postgres")
      ]
    ]
  end

  test "should receive events", context do
    start_repl!(context)

    insert_users(context, 1)

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "1"]},
      %Commit{}
    ]
  end

  describe "ack" do
    test "works", context do
      start_repl!(context)

      insert_users(context, [1, 2])

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{end_lsn: first_lsn}
      ]

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{end_lsn: second_lsn}
      ]

      PgSource.ack(source_id(context), first_lsn)

      restart_repl!(context)

      insert_users(context, 100)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "100"]},
        %Commit{end_lsn: end_lsn}
      ]

      PgSource.ack(source_id(context), end_lsn)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{end_lsn: ^second_lsn}
      ]

      refute_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{end_lsn: _final_lsn}
      ]
    end

    test "ignores the final_lsn that is less than the one in the state", context do
      start_repl!(context)

      insert_users(context, [1, 2, 3])

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{end_lsn: first_lsn}
      ]

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{end_lsn: second_lsn}
      ]

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "3"]},
        %Commit{end_lsn: third_lsn}
      ]

      PgSource.ack(source_id(context), second_lsn)
      PgSource.ack(source_id(context), first_lsn)

      restart_repl!(context)

      insert_users(context, 103)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "103"]},
        %Commit{end_lsn: end_lsn}
      ]

      PgSource.ack(source_id(context), end_lsn)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "3"]},
        %Commit{end_lsn: ^third_lsn}
      ]

      refute_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{}
      ]

      refute_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{}
      ]
    end
  end

  describe "should receive un-acked events" do
    setup context do
      start_repl!(context)

      insert_users(context, 1)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{end_lsn: final_lsn}
      ]

      PgSource.ack(source_id(context), final_lsn)
    end

    test "events that are not received previously", context do
      stop_repl!(context)

      insert_users(context, 2)

      start_repl!(context)

      insert_users(context, 102)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "102"]},
        %Commit{end_lsn: end_lsn}
      ]

      PgSource.ack(source_id(context), end_lsn)

      refute_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{}
      ]

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{}
      ]
    end

    test "events that are received previously", context do
      insert_users(context, 2)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{}
      ]

      restart_repl!(context)

      insert_users(context, 101)

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "101"]},
        %Commit{end_lsn: end_lsn}
      ]

      PgSource.ack(source_id(context), end_lsn)

      refute_receive [
        %Begin{},
        %Insert{tuple_data: [text: "1"]},
        %Commit{}
      ]

      assert_receive [
        %Begin{},
        %Insert{tuple_data: [text: "2"]},
        %Commit{}
      ]
    end
  end

  test "should not receive acked events", context do
    start_repl!(context)

    insert_users(context, 1)

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "1"]},
      %Commit{end_lsn: final_lsn}
    ]

    PgSource.ack(source_id(context), final_lsn)

    restart_repl!(context)

    insert_users(context, 2)

    refute_receive [
      %Begin{},
      %Insert{tuple_data: [text: "1"]},
      %Commit{}
    ]

    assert_receive [
      %Begin{},
      %Insert{tuple_data: [text: "2"]},
      %Commit{}
    ]
  end

  defp start_repl!(context) do
    source_pid =
      start_supervised!({PgSource, context.opts ++ [name: source_id(context)]},
        id: source_id(context)
      )

    start_supervised!({PgSourceRelayer, {source_pid, self()}}, id: relayer_id(context))
  end

  defp stop_repl!(context) do
    stop_supervised!(source_id(context))
    stop_supervised!(relayer_id(context))
  end

  defp restart_repl!(context) do
    stop_repl!(context)
    start_repl!(context)
  end

  defp insert_users(context, nos) do
    for no <- List.wrap(nos) do
      PSQL.cmd("INSERT INTO #{context.table_name} (id) VALUES (#{no});")
    end
  end

  defp source_id(context), do: :"source-#{context.module}-#{context.test}"
  defp relayer_id(context), do: :"relayer-#{context.module}-#{context.test}"

  defp case_identity(context) do
    "#{context.module |> Module.split() |> Enum.map_join(&Macro.underscore/1)}_#{context.line}"
  end
end
