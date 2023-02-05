defmodule PostgrexWal.Messages.Relation do
  @moduledoc """
  Relation messages identify column types by their OIDs.
  In the case of a built-in type, it is assumed that the client can look up that type OID locally, so no additional data is needed.
  For a non-built-in type OID, a Type message will be sent before the Relation message, to provide the type name associated with that OID.
  Thus, a client that needs to specifically identify the types of relation columns should cache the contents of Type messages,
  and first consult that cache to see if the type OID is defined there. If not, look up the type OID locally.
  """

  defmodule Column do
    @moduledoc """
    columns message.

    Int8
    Flags for the column. Currently can be either 0 for no flags or 1 which marks the column as part of the key.

    String
    Name of the column.

    Int32 (Oid)
    OID of the column's data type.

    Int32
    Type modifier of the column (atttypmod).
    """

    alias PostgrexWal.MessageUtil
    use TypedStruct

    typedstruct enforce: true do
      field :flags, Keyword.t()
      field :column_name, String.t()
      field :type_oid, integer()
      field :type_modifier, integer()
    end

    @spec decode(columns :: binary, acc :: list()) :: [t()]
    def decode(columns, acc \\ [])
    def decode(<<>>, acc), do: Enum.reverse(acc)

    def decode(<<flags::8, rest::binary>>, acc) do
      [
        column_name,
        <<type_oid::32, type_modifier::32, rest::binary>>
      ] = MessageUtil.binary_split(rest)

      decode(
        rest,
        [
          %__MODULE__{
            flags: [{:key, flags == 1}],
            column_name: column_name,
            type_oid: type_oid,
            type_modifier: type_modifier
          }
          | acc
        ]
      )
    end
  end

  use PostgrexWal.Message

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
    ] = MessageUtil.binary_split(rest, 3)

    %__MODULE__{
      relation_oid: relation_oid,
      namespace: MessageUtil.decode_namespace(namespace),
      relation_name: relation_name,
      flags: [
        {:setting, MessageUtil.decode_replica_identity_setting(replica_identity_setting)}
      ],
      number_of_columns: number_of_columns,
      columns: Column.decode(columns)
    }
  end
end
