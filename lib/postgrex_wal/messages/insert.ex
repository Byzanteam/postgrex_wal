defmodule PostgrexWal.Messages.Insert do
  @moduledoc """
  An insert message

  Byte1('I')
  Identifies the message as an insert message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int32 (Oid)
  OID of the relation corresponding to the ID in the relation message.

  Byte1('N')
  Identifies the following TupleData message as a new tuple.

  TupleData
  TupleData message part representing the contents of new tuple.
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer(), enforce: false
    field :relation_oid, integer()
    field :tuple_data, [Message.tuple_data()]
  end

  @impl true
  # protocol 1
  def decode(<<relation_oid::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      relation_oid: relation_oid,
      tuple_data: Util.decode_tuple_data!(tuple_data)
    }
  end

  # protocol 2
  def decode(<<transaction_id::32, relation_oid::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      relation_oid: relation_oid,
      tuple_data: Util.decode_tuple_data!(tuple_data)
    }
  end
end
