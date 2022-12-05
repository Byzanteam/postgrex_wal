defmodule PostgrexWalTest do
  use ExUnit.Case
  @moduletag timeout: 5_000

  setup do
    Process.register self(), Tester
    :ok
  end

  test "Consumer can receive: Xlogs "do
    pg_query("INSERT INTO users (name, age) VALUES ('abc', 21)")
    events = consumer_received_events()
    assert is_list(events)
    assert length(events) > 0
  end

  test "Consumer can receive Insert" do
    pg_query("INSERT INTO users (name, age) VALUES ('abc', 22)")
    assert events_is_a?("Insert")
  end

  test "Consumer can receive Update" do
    pg_query("UPDATE users SET age = 23 WHERE name = 'abc'")
    assert events_is_a?("Update")
  end

  test "Consumer can receive Delete" do
    pg_query("DELETE FROM users WHERE name = 'abc'")
    assert events_is_a?("Delete")
  end

  defp pg_query(qstr) do
    Process.whereis(PgConn) |> Postgrex.query(qstr, [])
  end

  defp events_is_a?(str) do
    consumer_received_events()
    |> Enum.any?(&(&1 |> Map.get(:__struct__) |> Atom.to_string |> String.ends_with?(str)))
  end

  defp consumer_received_events() do
    receive do {:consumer_events, events} -> events end
  end
end
