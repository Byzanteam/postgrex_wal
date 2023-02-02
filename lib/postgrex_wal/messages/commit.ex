defmodule PostgrexWal.Messages.Commit do
  @moduledoc """
  A commit message

  Byte1('C')
  Identifies the message as a commit message.

  Int8(0)
  Flags; currently unused.

  Int64 (XLogRecPtr)
  The LSN of the commit.

  Int64 (XLogRecPtr)
  The end LSN of the transaction.

  Int64 (TimestampTz)
  Commit timestamp of the transaction. The value is in number of microseconds since PostgreSQL epoch (2000-01-01).
  """

  use PostgrexWal.GenMessage

  typedstruct enforce: true do
    field :flags, Keyword.t()
    field :lsn, String.t()
    field :end_lsn, String.t()
    field :commit_timestamp, DateTime.t()
  end

  @impl true
  def decode(<<_flag::8, lsn::64, end_lsn::64, timestamp::64>>) do
    %__MODULE__{
      flags: [],
      lsn: MessageHelper.decode_lsn(lsn),
      end_lsn: MessageHelper.decode_lsn(end_lsn),
      commit_timestamp: MessageHelper.decode_timestamp(timestamp)
    }
  end

  def identifier, do: ?C
end
