defmodule SmokeTest do
  use ExUnit.Case, async: true
  import PgSourceTestHelper
  alias Postgrex, as: P

  setup do
    opts = [database: "postgres", backoff_type: :stop]
    {:ok, pid} = P.start_link(opts)
    {:ok, [pid: pid]}
  end

  test "decode time", context do
    assert [[~T[04:05:06.000000]]] = query("SELECT time '04:05:06 PST'", [])
  end
end
