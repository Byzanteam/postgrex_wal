defmodule PostgrexWal.Message.Truncate do
  @moduledoc """
  A Truncate message
  """
  use PostgrexWal.Message
  defstruct ~W[number_of_relations options truncated_relations]a

  def decode(<<number_of_relations::integer-32, options::integer-8, column_ids::binary>>) do
    truncated_relations =
      for relation_id_bin <- column_ids |> :binary.bin_to_list() |> Enum.chunk_every(4),
          do: relation_id_bin |> :binary.list_to_bin() |> :binary.decode_unsigned()

    decoded_options =
      case options do
        0 -> []
        1 -> [:cascade]
        2 -> [:restart_identity]
      end

    %__MODULE__{
      number_of_relations: number_of_relations,
      options: decoded_options,
      truncated_relations: truncated_relations
    }
  end
end
