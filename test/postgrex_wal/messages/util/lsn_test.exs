defmodule PostgrexWal.Messages.Util.LSNTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Util.LSN

  test "to_str/1, from_str/1 behaves as expected" do
    assert "0/2E3FBE8" == "0/2E3FBE8" |> LSN.from_str() |> LSN.to_str()
    assert 48_495_592 == 48_495_592 |> LSN.to_str() |> LSN.from_str()
    assert 48_495_592 == LSN.from_str("0/2E3FBE8")
    assert "0/2E3FBE8" == LSN.to_str(48_495_592)
  end
end
