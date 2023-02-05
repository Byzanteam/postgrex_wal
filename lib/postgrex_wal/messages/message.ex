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
    field :transaction_id, integer(), enforce: false
    field :flags, [{:transactional, boolean()}]
    field :lsn, String.t()
    field :prefix, String.t()
    field :content, String.t()
  end

  @impl true
  def decode(<<flags::8, lsn::64, rest::binary>>) do
    [
      prefix,
      <<n::32, content::binary-size(n)>>
    ] = MessageUtil.binary_split(rest)

    %__MODULE__{
      flags: [{:transactional, flags == 1}],
      lsn: MessageUtil.decode_lsn(lsn),
      prefix: prefix,
      content: content
    }
  end
end
