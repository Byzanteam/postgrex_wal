defmodule PostgrexWal.Message.Truncate do
  @moduledoc """
  A Truncate message
  """
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :number_of_relations, integer()
    field :options, list()
    field :truncated_relations, integer()
  end

  @dict %{
    0 => [],
    1 => [:cascade],
    2 => [:restart_identity]
  }

  @impl true
  def decode(<<number_of_relations::32, options::8, column_ids::binary>>) do
    truncated_relations =
      for relation_id_bin <- column_ids |> :binary.bin_to_list() |> Enum.chunk_every(4),
          do: relation_id_bin |> :binary.list_to_bin() |> :binary.decode_unsigned()

    %__MODULE__{
      number_of_relations: number_of_relations,
      options: @dict[options],
      truncated_relations: truncated_relations
    }
  end
end
