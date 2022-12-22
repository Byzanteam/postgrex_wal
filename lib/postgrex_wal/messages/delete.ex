defmodule PostgrexWal.Messages.Delete do
  @moduledoc """
  A delete message.

  Byte1('D')
  Identifies the message as a delete message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int32 (Oid)
  OID of the relation corresponding to the ID in the relation message.

  Byte1('K')
  Identifies the following TupleData submessage as a key. This field is present if the table in which the delete has happened uses an index as REPLICA IDENTITY.

  Byte1('O')
  Identifies the following TupleData message as an old tuple. This field is present if the table in which the delete happened has REPLICA IDENTITY set to FULL.

  TupleData
  TupleData message part representing the contents of the old tuple or primary key, depending on the previous field.

  The Delete message may contain either a 'K' message part or an 'O' message part, but never both of them.
  """

  use PostgrexWal.Message

  typedstruct do
    field :transaction_id, integer(), enforce: true
    field :relation_oid, integer(), enforce: true
    field :changed_key_tuple_data, [Message.tuple_data()]
    field :old_tuple_data, [Message.tuple_data()]
  end

  @impl true
  def decode(<<transaction_id::32, relation_oid::32, ?K, tuple_data::binary>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      relation_oid: relation_oid,
      changed_key_tuple_data: Util.decode_tuple_data!(tuple_data)
    }
  end

  def decode(<<transaction_id::32, relation_oid::32, ?O, tuple_data::binary>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      relation_oid: relation_oid,
      old_tuple_data: Util.decode_tuple_data!(tuple_data)
    }
  end
end
