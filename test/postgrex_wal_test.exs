defmodule PostgrexWalTest do
  use ExUnit.Case

  setup do
    {:ok, conn} = Application.fetch_env!(:postgrex_wal, :db_conn_info) |> Postgrex.start_link
    #prepare test data in table
    conn |> pg_query("INSERT INTO users (name, age) VALUES ('test_user', 20)")
    consumer_received_events()

    {:ok, [conn: conn]}
  end

  test "can fetch events from consumer", context do
    context[:conn] |> pg_query("INSERT INTO users (name, age) VALUES ('test_user', 21)")
    events = consumer_received_events()
    assert is_list(events)
    assert length(events) > 0
  end

  test "consumer can receive Inert Xlog", context do
    context[:conn] |> pg_query("INSERT INTO users (name, age) VALUES ('test_user', 22)")
    assert events_is_a?("Insert")
  end

  test "consumer can receive Update Xlog", context do
    context[:conn] |> pg_query("UPDATE users SET age = 23 WHERE name = 'test_user'")
    assert events_is_a?("Update")
  end

  test "consumer can receive Delete Xlog", context do
    context[:conn] |> pg_query("DELETE FROM users WHERE name = 'test_user'")
    assert events_is_a?("Delete")
  end

  defp consumer_received_events() do
    alias PostgrexWal.GenStage.MockedConsumer, as: C
    #sleep 1second wait for events
    Process.sleep(:timer.seconds(1))
    C.events_fetch() |> Enum.reverse
  end

  defp pg_query(conn, qstr) do
    conn |> Postgrex.query(qstr, [])
  end

  defp events_is_a?(str) do
    consumer_received_events()
    |> Enum.any?(&(&1 |> Map.get(:__struct__) |> Atom.to_string |> String.ends_with?(str)))
  end
end
