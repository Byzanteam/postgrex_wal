defmodule PostgrexWal.Message.DeleteMessage do
  @moduledoc """
  A delete message.
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :relation_id, integer()
    field :data, [map()]
  end

  def decode(_state) do
    quote location: :keep do
      <<?D, relation_id::32, ?K, tuple_data::binary>> ->
        %unquote(__MODULE__){
          relation_id: relation_id,
          data: PostgrexWal.Message.TupleData.decode(tuple_data)
        }

      <<?D, relation_id::32, ?O, tuple_data::binary>> ->
        %unquote(__MODULE__){
          relation_id: relation_id,
          data: PostgrexWal.Message.TupleData.decode(tuple_data)
        }
    end
  end
end
