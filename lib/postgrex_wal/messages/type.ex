defmodule PostgrexWal.Messages.Type do
  @moduledoc """
  Relation messages identify column types by their OIDs.
  In the case of a built-in type, it is assumed that the client can look up that type OID locally, so no additional data is needed.
  For a non-built-in type OID, a Type message will be sent before the Relation message, to provide the type name associated with that OID.
  Thus, a client that needs to specifically identify the types of relation columns should cache the contents of Type messages,
  and first consult that cache to see if the type OID is defined there. If not, look up the type OID locally.
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer(), enforce: false
    field :type_oid, integer()
    field :namespace, String.t()
    field :type_name, String.t()
  end

  @doc """
  A Type message

  Byte1('Y')
  Identifies the message as a type message.

  Int32 (TransactionId)
  Xid of the transaction (only present for streamed transactions). This field is available since protocol version 2.

  Int32 (Oid)
  OID of the data type.

  String
  Namespace (empty string for pg_catalog).

  String
  Name of the data type.
  """
  @impl true
  def decode(<<type_oid::32, namespace_and_name::binary>>) do
    [namespace, name, _] = Util.binary_split(namespace_and_name, 3)

    %__MODULE__{
      type_oid: type_oid,
      namespace: Util.decode_namespace(namespace),
      type_name: name
    }
  end

  def identifier, do: ?T
end
