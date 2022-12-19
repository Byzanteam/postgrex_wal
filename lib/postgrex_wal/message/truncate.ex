defmodule PostgrexWal.Message.Truncate do
  @moduledoc """
  A Truncate message

  Byte1('T')
  Identifies the message as a truncate message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int32
  Number of relations

  Int8
  Option bits for TRUNCATE: 1 for CASCADE, 2 for RESTART IDENTITY

  Int32 (Oid)
  OID of the relation corresponding to the ID in the relation message. This field is repeated for each relation.
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
