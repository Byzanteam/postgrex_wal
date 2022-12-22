defmodule PostgrexWal.Messages.Type do
  @moduledoc """
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
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :transaction_id, integer()
    field :oid, integer()
    field :namespace, String.t()
    field :name, String.t()
  end

  @impl true
  def decode(<<transaction_id::32, oid::32, namespace_and_name::binary>>) do
    [namespace, name, _] = Util.binary_split(namespace_and_name, 3)

    %__MODULE__{
      transaction_id: transaction_id,
      oid: oid,
      namespace: namespace,
      name: name
    }
  end
end
