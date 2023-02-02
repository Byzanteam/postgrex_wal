defmodule PostgrexWal.Messages.Update do
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
    field :transaction_id, integer()
    field :relation_oid, integer(), enforce: true
    field :tuple_data, [Message.tuple_data()], enforce: true
    field :changed_key_tuple_data, [Message.tuple_data()]
    field :old_tuple_data, [Message.tuple_data()]
  end

  @impl true
  def decode(<<relation_oid::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      relation_oid: relation_oid,
      tuple_data: Util.decode_tuple_data(tuple_data)
    }
  end

  def decode(<<_relation_oid::32, ?K, _tuple_data::binary>> = payload) do
    do_decode(payload, :changed_key_tuple_data)
  end

  def decode(<<_relation_oid::32, ?O, _tuple_data::binary>> = payload) do
    do_decode(payload, :old_tuple_data)
  end

  defp do_decode(<<relation_oid::32, _k_or_o, tuple_data::binary>>, key) do
    {<<?N, new_tuple_data::binary>>, old_decoded_tuple_data} = Util.split_tuple_data(tuple_data)

    struct(__MODULE__, [
      {:relation_oid, relation_oid},
      {:tuple_data, Util.decode_tuple_data(new_tuple_data)},
      {key, old_decoded_tuple_data}
    ])
  end

  def identifier, do: ?U
end
