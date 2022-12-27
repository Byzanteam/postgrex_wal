defmodule PostgrexWal.Messages.Relation.Column do
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

  alias PostgrexWal.Messages.Util
  use TypedStruct

  typedstruct enforce: true do
    field :flags, integer()
    field :column_name, String.t()
    field :type_oid, atom()
    field :type_modifier, integer()
  end

  @spec decode(columns :: binary, acc :: list()) :: [t()]
  def decode(columns, acc \\ [])
  def decode(<<>>, acc), do: Enum.reverse(acc)

  def decode(<<flags::8, rest::binary>>, acc) do
    [
      column_name,
      <<type_oid::32, type_modifier::32, rest::binary>>
    ] = Util.binary_split(rest)

    decode(
      rest,
      [
        %__MODULE__{
          flags: (flags == 1 && [:key]) || [],
          column_name: column_name,
          type_oid: type_oid,
          type_modifier: type_modifier
        }
        | acc
      ]
    )
  end
end
