defmodule PostgrexWal.Messages.Util.LSN do
  @moduledoc """
  LSN (Log Sequence Number) is a pointer to a location in the WAL.

  Internally, an LSN is a 64-bit integer, representing a byte position in the write-ahead log stream.
  It is printed as two hexadecimal numbers of up to 8 digits each, separated by a slash; for example, 16/B374D848.

  This module provides utility functions for encoding/decoding Lsn's
  """
  @spec decode(lsn :: integer) :: String.t()
  def decode(lsn) when is_integer(lsn) do
    <<xlog_file_id::32, xlog_offset::32>> = <<lsn::64>>
    Integer.to_string(xlog_file_id, 16) <> "/" <> Integer.to_string(xlog_offset, 16)
  end

  @spec encode(lsn :: String.t()) :: integer
  def encode(lsn) when is_binary(lsn) do
    [xlog_file_id, xlog_offset] = String.split(lsn, "/", trim: true)

    <<lsn::64>> =
      <<String.to_integer(xlog_file_id, 16)::32, String.to_integer(xlog_offset, 16)::32>>

    lsn
  end
end
