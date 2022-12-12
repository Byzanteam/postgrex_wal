defmodule PostgrexWal.Message.Insert do
  @moduledoc """
  An insert message
  """

  use PostgrexWal.Message
  alias PostgrexWal.Message.TupleData

  typedstruct enforce: true do
    field :transaction_id, integer(), enforce: false
    field :oid, integer()
    field :data, {:text, binary()} | {:binary, bitstring()}, enforce: false
  end

  def decode(_state) do
    quote location: :keep do
      <<?I, transaction_id::32, oid::32, ?N, tuple_data::binary>> ->
        %unquote(__MODULE__){
          transaction_id: transaction_id,
          oid: oid,
          data: TupleData.decode(tuple_data)
        }

      <<?I, oid::32, ?N, tuple_data::binary>> ->
        %unquote(__MODULE__){
          oid: oid,
          data: TupleData.decode(tuple_data)
        }
    end
  end
end
