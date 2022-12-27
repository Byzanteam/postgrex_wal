defmodule PostgrexWal.Messages.Util.LSNTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Util.LSN

  test "to_str/1, from_str/1 behaves as expected" do
    assert "0/2E3FBE8" == "0/2E3FBE8" |> LSN.encode() |> LSN.decode()
    assert 48_495_592 == 48_495_592 |> LSN.decode() |> LSN.encode()
    assert 48_495_592 == LSN.encode("0/2E3FBE8")
    assert "0/2E3FBE8" == LSN.decode(48_495_592)
  end
end
