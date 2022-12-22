defmodule PostgrexWal.Messages.StreamCommit do
  @moduledoc """
  Byte1('c')
  Identifies the message as a stream commit message.

  Int32 (TransactionId)
  Xid of the transaction.

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
    field :transaction_id, integer()
    field :flags, []
    field :lsn, Message.lsn()
    field :final_lsn, Message.lsn()
    field :commit_timestamp, DateTime.t()
  end

  @impl true
  def decode(<<transaction_id::32, _flags::8, lsn::binary-8, final_lsn::binary-8, timestamp::64>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      flags: [],
      lsn: Util.decode_lsn(lsn),
      final_lsn: Util.decode_lsn(final_lsn),
      commit_timestamp: Util.decode_timestamp(timestamp)
    }
  end
end
