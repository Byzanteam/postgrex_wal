defmodule PostgrexWal.Message.Relation do
  @moduledoc """
  A relation message.
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :id, integer()
    field :namespace, String.t()
    field :relation_name, String.t()
    field :replica_identity_setting, integer()
    field :number_of_columns, integer()
    field :data, [map()]
  end

  def decode(<<id::32, rest::binary>>) do
    [namespace, rest] = split(rest)
    [relation_name, rest] = split(rest)
    <<replica_identity_setting::8, number_of_columns::16, rest::binary>> = rest

    data = extract_columns(rest)

    %__MODULE__{
      id: id,
      namespace: namespace,
      relation_name: relation_name,
      replica_identity_setting: replica_identity_setting,
      number_of_columns: number_of_columns,
      data: data
    }
  end

  @null_terminator <<0>>

  def split(binary) when is_binary(binary) do
    String.split(binary, @null_terminator, parts: 2)
  end

  def extract_columns(data, accumulator \\ [])
  def extract_columns(<<>>, accumulator), do: Enum.reverse(accumulator)

  def extract_columns(<<flags::8, data::binary>>, accumulator) do
    [column_name, <<type_oid::32, type_modifier::32, rest::binary>>] = split(data)

    extract_columns(
      rest,
      [
        %{
          flags: flags,
          column_name: column_name,
          type_oid: type_oid,
          type_modifier: type_modifier
        }
        | accumulator
      ]
    )
  end
end
