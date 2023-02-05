defmodule PostgrexWal.MessageUtilTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.MessageUtil

  test "decode_lsn/1 behaves as expected" do
    assert "0/2E3FBE8" == "0/2E3FBE8" |> encode_lsn() |> MessageUtil.decode_lsn()
    assert 48_495_592 == 48_495_592 |> MessageUtil.decode_lsn() |> encode_lsn()
    assert 48_495_592 == encode_lsn("0/2E3FBE8")
    assert "0/2E3FBE8" == MessageUtil.decode_lsn(48_495_592)
  end

  @spec encode_lsn(lsn :: String.t()) :: integer
  defp encode_lsn(lsn) when is_binary(lsn) do
    [xlog_file_id, xlog_offset] = String.split(lsn, "/", trim: true)

    <<lsn::64>> =
      <<String.to_integer(xlog_file_id, 16)::32, String.to_integer(xlog_offset, 16)::32>>

    lsn
  end
end
