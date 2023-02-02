defmodule PostgrexWal.Messages.StreamStart do
  @moduledoc """
  Byte1('S')
  Identifies the message as a stream start message.

  Int32 (TransactionId)
  Xid of the transaction.

  Int8
  A value of 1 indicates this is the first stream segment for this XID, 0 for any other stream segment.
  """
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer()
    field :flags, [{:first_segment, boolean()}]
  end

  @impl true
  def decode(<<transaction_id::32, flags::8>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      flags: [{:first_segment, flags == 1}]
    }
  end

  @impl true
  def identifier, do: ?S
end
