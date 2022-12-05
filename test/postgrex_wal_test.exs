defmodule PostgrexWalTest do
  use ExUnit.Case
  @moduletag timeout: 5_000

  setup do
    Process.register self(), Tester
    :ok
  end

  test "Consumer can receive Insert" do
    pg_query("INSERT INTO users (name, age) VALUES ('abc', 22)")
    assert transaction_is?(events(), "Insert")
  end

  test "Consumer can receive Update" do
    pg_query("UPDATE users SET age = 23 WHERE name = 'abc'")
    assert transaction_is?(events(), "Update")
  end

  test "Consumer can receive Delete" do
    pg_query("DELETE FROM users WHERE name = 'abc'")
    assert transaction_is?(events(), "Delete")
  end

  defp pg_query(qstr) do
    Process.whereis(PgConn) |> Postgrex.query(qstr, [])
  end

  defp transaction_is?(events, str) do
    name = String.to_atom "Elixir.PgoutputDecoder.Messages.#{str}"
    events |> Enum.any?(&(is_struct(&1, name)))
  end

  defp events() do
    receive do {:consumer_events, events} -> events end
  end
end
