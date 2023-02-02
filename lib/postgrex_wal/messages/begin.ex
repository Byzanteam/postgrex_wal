defmodule PostgrexWal.Messages.Begin do
  @moduledoc """
  A begin message

  Byte1('B')
  Identifies the message as a begin message.

  Int64 (XLogRecPtr)
  The final LSN of the transaction.

  Int64 (TimestampTz)
  Commit timestamp of the transaction. The value is in number of microseconds since PostgreSQL epoch (2000-01-01).

  Int32 (TransactionId)
  Xid of the transaction.
  """
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :final_lsn, String.t()
    field :commit_timestamp, DateTime.t()
    field :transaction_id, integer()
  end

  @impl true
  def decode(<<lsn::64, timestamp::64, transaction_id::32>>) do
    %__MODULE__{
      final_lsn: Util.decode_lsn(lsn),
      commit_timestamp: Util.decode_timestamp(timestamp),
      transaction_id: transaction_id
    }
  end

  @impl true
  def identifier, do: ?B
end
