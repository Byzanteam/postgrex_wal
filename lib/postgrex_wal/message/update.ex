defmodule PostgrexWal.Message.Update do
  @moduledoc """
  An insert message
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
