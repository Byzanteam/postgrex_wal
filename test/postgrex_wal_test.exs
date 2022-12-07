defmodule PostgrexWalTest do
  use ExUnit.Case
  @moduletag timeout: 5_000
  alias PgoutputDecoder.Messages.{Begin, Insert, Update, Delete, Commit}

  setup do
    Process.register(self(), Tester)
    :ok
  end

  test "Consumer can receive Insert" do
    pg_query("INSERT INTO users (name, age) VALUES ('abc', 22)")
    assert received_events() |> valid_events?(Insert)
  end

  test "Consumer can receive Update" do
    pg_query("UPDATE users SET age = 23 WHERE name = 'abc'")
    assert received_events() |> valid_events?(Update)
  end

  test "Consumer can receive Delete" do
    pg_query("DELETE FROM users WHERE name = 'abc'")
    assert received_events() |> valid_events?(Delete)
  end

  defp pg_query(qstr) do
    Process.whereis(PgConn) |> Postgrex.query(qstr, [])
  end

  defp valid_events?(events, name) do
    events |> Enum.any?(&is_struct(&1, name)) &&
      events |> List.first() |> is_struct(Begin) &&
      events |> List.last() |> is_struct(Commit)
  end

  defp received_events() do
    receive do
      {:consumer_events, events} -> events
    end
  end
end
