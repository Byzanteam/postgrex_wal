defmodule PostgrexWal.Message.Delete do
  @moduledoc """
  A delete message.
  """

  use PostgrexWal.Message

  typedstruct do
    field :relation_id, integer(), enforce: true
    field :changed_key_tuple_data, [Helper.tuple_data()]
    field :old_tuple_data, [Helper.tuple_data()]
  end

  @impl true
  def decode(<<relation_id::32, ?K, tuple_data::binary>>) do
    %__MODULE__{
      relation_id: relation_id,
      changed_key_tuple_data: Helper.decode_tuple_data!(tuple_data)
    }
  end

  def decode(<<relation_id::32, ?O, tuple_data::binary>>) do
    %__MODULE__{
      relation_id: relation_id,
      old_tuple_data: Helper.decode_tuple_data!(tuple_data)
    }
  end
end
