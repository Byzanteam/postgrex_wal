defmodule PostgrexWal.Message.Commit do
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

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :flags, []
    field :lsn, Helper.lsn()
    field :end_lsn, Helper.lsn()
    field :commit_timestamp, DateTime.t()
  end

  @impl true
  def decode(<<_flag::8, lsn::binary-8, end_lsn::binary-8, timestamp::64>>) do
    %__MODULE__{
      flags: [],
      lsn: Helper.decode_lsn(lsn),
      end_lsn: Helper.decode_lsn(end_lsn),
      commit_timestamp: Helper.decode_timestamp(timestamp)
    }
  end
end
