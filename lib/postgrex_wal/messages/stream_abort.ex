defmodule PostgrexWal.Messages.StreamAbort do
  @moduledoc """
  Byte1('A')
  Identifies the message as a stream abort message.

  Int32 (TransactionId)
  Xid of the transaction.

  Int32 (TransactionId)
  Xid of the subtransaction (will be same as xid of the transaction for top-level transactions).
  """
  use PostgrexWal.GenMessage

  typedstruct enforce: true do
    field :transaction_id, integer()
    field :sub_transaction_id, integer()
  end

  @impl true
  def decode(<<transaction_id::32, sub_transaction_id::32>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      sub_transaction_id: sub_transaction_id
    }
  end

  def identifier, do: ?A
end
