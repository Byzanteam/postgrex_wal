defmodule PostgrexWal.Message.Insert do
  @moduledoc """
  An insert message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer(), enforce: false
    field :oid, integer()
    field :data, {:text, binary()} | {:binary, bitstring()}, enforce: false
  end

  def decode(<<ransaction_id::32, oid::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      oid: oid,
      data: PostgrexWal.Message.TupleData.decode(tuple_data)
    }
  end

  def decode(<<oid::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      oid: oid,
      data: PostgrexWal.Message.TupleData.decode(tuple_data)
    }
  end
end
