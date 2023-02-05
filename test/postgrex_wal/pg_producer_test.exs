defmodule PostgrexWal.PgProducerTest do
  use ExUnit.Case, async: false

  alias PostgrexWal.Messages.Insert
  alias PostgrexWal.PSQL

  defmodule MyBroadway do
    use Broadway

    def start_link(opts) do
      {tester, opts} = Keyword.pop!(opts, :tester)

      Broadway.start_link(__MODULE__,
        name: __MODULE__,
        producer: [
          module: {PostgrexWal.PgProducer, opts},
          concurrency: 1
        ],
        processors: [
          default: [concurrency: 1]
        ],
        context: %{tester: tester}
      )
    end

    @impl true
    def handle_message(_processor_name, message, context) do
      send(context.tester, message)
      message
    end
  end

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
      opts:
        [
          publication_name: publication_name,
          slot_name: slot_name
        ] ++ PSQL.pg_env() ++ [tester: self()]
    ]
  end

  test "should receive broadway message", context do
    start_my_broadway(context)
    insert_users(context, 1)
    assert_receive %Broadway.Message{data: %Insert{tuple_data: [text: "1"]}}
  end

  test "should receive previously un-acked message", context do
    insert_users(context, 2)
    start_my_broadway(context)
    assert_receive %Broadway.Message{data: %Insert{tuple_data: [text: "2"]}}
  end

  test "should auto-ack message", context do
    start_my_broadway(context)
    insert_users(context, 3)
    assert_receive %Broadway.Message{data: %Insert{tuple_data: [text: "3"]}}

    restart_my_broadway(context)
    refute_receive %Broadway.Message{data: %Insert{tuple_data: [text: "3"]}}
  end

  defp start_my_broadway(context) do
    start_supervised!({MyBroadway, context.opts}, id: source_id(context))
  end

  defp stop_my_broadway(context) do
    stop_supervised!(source_id(context))
  end

  defp restart_my_broadway(context) do
    stop_my_broadway(context)
    start_my_broadway(context)
  end

  defp insert_users(context, nos) do
    for no <- List.wrap(nos) do
      PSQL.cmd("INSERT INTO #{context.table_name} (id) VALUES (#{no});")
    end
  end

  defp source_id(context), do: :"source-#{context.module}-#{context.test}"

  defp case_identity(context) do
    "#{context.module |> Module.split() |> Enum.map_join(&Macro.underscore/1)}_#{context.line}"
  end
end
