defmodule PostgrexWal.Messages.Truncate do
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
    field :transaction_id, integer(), enforce: false
    field :number_of_relations, integer()
    field :options, [{:truncate, :cascade | :restart_identity}]
    field :relation_oids, list(integer)
  end

  @dict %{
    0 => [],
    1 => [:cascade],
    2 => [:restart_identity]
  }

  @impl true
  def decode(<<number_of_relations::32, options::8, relations::binary>>) do
    relation_oids = for <<column_id::32 <- relations>>, do: column_id

    %__MODULE__{
      number_of_relations: number_of_relations,
      options: [{:truncate, @dict[options]}],
      relation_oids: relation_oids
    }
  end

  @impl true
  def identifier, do: ?T
end
