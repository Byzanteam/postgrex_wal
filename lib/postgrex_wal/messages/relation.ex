defmodule PostgrexWal.Messages.Relation do
  @moduledoc """
  Relation messages identify column types by their OIDs.
  In the case of a built-in type, it is assumed that the client can look up that type OID locally, so no additional data is needed.
  For a non-built-in type OID, a Type message will be sent before the Relation message, to provide the type name associated with that OID.
  Thus, a client that needs to specifically identify the types of relation columns should cache the contents of Type messages,
  and first consult that cache to see if the type OID is defined there. If not, look up the type OID locally.
  """

  use PostgrexWal.Message
  alias PostgrexWal.Messages.Relation.Column

  typedstruct enforce: true do
    field :transaction_id, integer(), enforce: false
    field :relation_oid, integer()
    field :namespace, String.t()
    field :relation_name, String.t()

    field :flags, [
      {:setting, :default | :nothing | :all_columns | :index}
    ]

    field :number_of_columns, integer()
    field :columns, [Column.t(), ...]
  end

  @doc """
  A relation message.

  Byte1('R')
  Identifies the message as a relation message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int32 (Oid)
  OID of the relation.

  String
  Namespace (empty string for pg_catalog).

  String
  Relation name.

  Int8
  Replica identity setting for the relation (same as relreplident in pg_class).

  Int16
  Number of columns.

  Next, the following message part appears for each column included in the publication (except generated columns):

  Int8
  Flags for the column. Currently can be either 0 for no flags or 1 which marks the column as part of the key.

  String
  Name of the column.

  Int32 (Oid)
  OID of the column's data type.

  Int32
  Type modifier of the column (atttypmod).
  """
  @impl true
  def decode(<<relation_oid::32, rest::binary>>) do
    [
      namespace,
      relation_name,
      <<replica_identity_setting::8, number_of_columns::16, columns::binary>>
    ] = Util.binary_split(rest, 3)

    %__MODULE__{
      relation_oid: relation_oid,
      namespace: Util.decode_namespace(namespace),
      relation_name: relation_name,
      flags: [
        {:setting, Util.decode_replica_identity_setting(replica_identity_setting)}
      ],
      number_of_columns: number_of_columns,
      columns: Column.decode(columns)
    }
  end
end
