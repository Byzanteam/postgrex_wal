defmodule PostgrexWal.Message.Type do
  @moduledoc """
  A Type message
  """
  use PostgrexWal.Message
  defstruct ~W[id namespace name]a

  @impl true
  def decode(<<data_type_id::integer-32, namespace_and_name::binary>>) do
    [namespace, name_with_null] = :binary.split(namespace_and_name, <<0>>)
    name = String.slice(name_with_null, 0..-2)

    %__MODULE__{
      id: data_type_id,
      namespace: namespace,
      name: name
    }
  end
end
