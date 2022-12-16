defmodule PostgrexWal.Message.Insert do
  @moduledoc """
  An insert message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer(), enforce: false
    field :relation_id, integer()
    field :tuple_data, [Helper.tuple_data()]
  end

  @impl true
  # seems unused
  def decode(<<transaction_id::32, relation_id::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      transaction_id: transaction_id,
      relation_id: relation_id,
      tuple_data: Helper.decode_tuple_data!(tuple_data)
    }
  end

  def decode(<<relation_id::32, ?N, tuple_data::binary>>) do
    %__MODULE__{
      relation_id: relation_id,
      tuple_data: Helper.decode_tuple_data!(tuple_data)
    }
  end
end
