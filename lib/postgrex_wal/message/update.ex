defmodule PostgrexWal.Message.Update do
  @moduledoc """
  An insert message

  Byte1('U')
  Identifies the message as an update message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int32 (Oid)
  OID of the relation corresponding to the ID in the relation message.

  Byte1('K')
  Identifies the following TupleData submessage as a key. This field is optional and is only present if the update changed data in any of the column(s) that are part of the REPLICA IDENTITY index.

  Byte1('O')
  Identifies the following TupleData submessage as an old tuple. This field is optional and is only present if table in which the update happened has REPLICA IDENTITY set to FULL.

  TupleData
  TupleData message part representing the contents of the old tuple or primary key. Only present if the previous 'O' or 'K' part is present.

  Byte1('N')
  Identifies the following TupleData message as a new tuple.

  TupleData
  TupleData message part representing the contents of a new tuple.

  The Update message may contain either a 'K' message part or an 'O' message part or neither of them, but never both of them.
  """

  use PostgrexWal.Message

  typedstruct do
    field :relation_id, integer(), enforce: true
    field :tuple_data, [Helper.tuple_data()], enforce: true
    field :changed_key_tuple_data, [Helper.tuple_data()]
    field :old_tuple_data, [Helper.tuple_data()]
  end

  @impl true
  def decode(<<relation_id::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      relation_id: relation_id,
      tuple_data: Helper.decode_tuple_data!(tuple_data)
    }
  end

  def decode(<<relation_id::32, ?K, tuple_data::binary>>) do
    {<<?N, new_tuple_data::binary>>, old_decoded_tuple_data} =
      Helper.decode_tuple_data(tuple_data)

    %__MODULE__{
      relation_id: relation_id,
      tuple_data: Helper.decode_tuple_data!(new_tuple_data),
      changed_key_tuple_data: old_decoded_tuple_data
    }
  end

  def decode(<<relation_id::32, ?O, tuple_data::binary>>) do
    {<<?N, new_tuple_data::binary>>, old_decoded_tuple_data} =
      Helper.decode_tuple_data(tuple_data)

    %__MODULE__{
      relation_id: relation_id,
      tuple_data: Helper.decode_tuple_data!(new_tuple_data),
      old_tuple_data: old_decoded_tuple_data
    }
  end
end
