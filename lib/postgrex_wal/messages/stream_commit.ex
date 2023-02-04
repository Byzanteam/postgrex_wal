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
    field :flags, Keyword.t(), default: []
    field :lsn, String.t()
    field :end_lsn, String.t()
    field :commit_timestamp, DateTime.t()
  end

  @impl true
  def decode(<<transaction_id::32, _flags::8, lsn::64, end_lsn::64, timestamp::64>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      lsn: MessageUtil.decode_lsn(lsn),
      end_lsn: MessageUtil.decode_lsn(end_lsn),
      commit_timestamp: MessageUtil.decode_timestamp(timestamp)
    }
  end

  @impl true
  def identifier, do: ?c
end
