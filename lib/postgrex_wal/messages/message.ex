defmodule PostgrexWal.Messages.Message do
  @moduledoc """
  Byte1('M')
  Identifies the message as a logical decoding message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int8
  Flags; Either 0 for no flags or 1 if the logical decoding message is transactional.

  Int64 (XLogRecPtr)
  The LSN of the logical decoding message.

  String
  The prefix of the logical decoding message.

  Int32
  Length of the content.

  Byten
  The content of the logical decoding message.

  """
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer()
    field :flags, [{:transactional, boolean}]
    field :lsn, Message.lsn()
    field :prefix, String.t()
    field :content, String.t()
  end

  @impl true
  def decode(<<transaction_id::32, flags::8, lsn::binary-8, rest::binary>>) do
    [
      prefix,
      <<n::32, content::binary-size(n)>>
    ] = Util.binary_split(rest)

    %__MODULE__{
      transaction_id: transaction_id,
      flags: [{:transactional, flags == 1}],
      lsn: Util.decode_lsn(lsn),
      prefix: prefix,
      content: content
    }
  end
end
