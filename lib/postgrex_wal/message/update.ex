defmodule PostgrexWal.Message.Update do
  @moduledoc """
  An insert message
  """

  use PostgrexWal.Message
  alias PostgrexWal.Message.TupleData
  defstruct ~W[relation_id tuple_data]a

  def decode(<<relation_id::integer-32, _key_or_old::binary-1, tuple_data::binary>>) do
    %__MODULE__{
      relation_id: relation_id,
      tuple_data: TupleData.decode(tuple_data)
    }
  end
end
