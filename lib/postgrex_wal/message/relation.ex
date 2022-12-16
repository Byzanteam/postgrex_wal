defmodule PostgrexWal.Message.Relation do
  @moduledoc """
  A relation message.
  """

  use PostgrexWal.Message
  alias PostgrexWal.Message.Relation.Column

  typedstruct enforce: true do
    field :id, integer()
    field :namespace, String.t()
    field :relation_name, String.t()
    field :replica_identity_setting, integer()
    field :number_of_columns, integer()
    field :columns, [%Column{}, ...]
  end

  @dict %{
    ?d => :default,
    ?n => :nothing,
    ?f => :all_columns,
    ?i => :index
  }

  def decode(<<id::32, rest::binary>>) do
    [
      namespace,
      relation_name,
      <<replica_identity_setting::8, number_of_columns::16, columns::binary>>
    ] = Helper.binary_split(rest, 3)

    %__MODULE__{
      id: id,
      namespace: namespace,
      relation_name: relation_name,
      replica_identity_setting: Map.fetch!(@dict, replica_identity_setting),
      number_of_columns: number_of_columns,
      columns: Column.decode(columns)
    }
  end
end
