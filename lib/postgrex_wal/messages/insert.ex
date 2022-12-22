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
    field :xid, integer(), enforce: false
    field :relation_id, integer()
    field :tuple_data, [Message.tuple_data()]
  end

  @impl true
  # NOTE: seems unused
  def decode(<<xid::32, relation_id::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      xid: xid,
      relation_id: relation_id,
      tuple_data: Util.decode_tuple_data!(tuple_data)
    }
  end

  def decode(<<relation_id::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      relation_id: relation_id,
      tuple_data: Util.decode_tuple_data!(tuple_data)
    }
  end
end
