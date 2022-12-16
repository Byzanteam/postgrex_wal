defmodule PostgrexWal.Message.Relation.Column do
  @moduledoc false

  alias PostgrexWal.Message.Helper
  use TypedStruct

  typedstruct enforce: true do
    field :flags, integer()
    field :column_name, String.t()
    field :type_oid, atom()
    field :type_modifier, integer()
  end

  @dict %{
    16 => :bool,
    17 => :bytea,
    18 => :char,
    20 => :int8,
    21 => :int2,
    23 => :int4,
    25 => :text,
    114 => :json,
    600 => :point,
    650 => :cidr,
    700 => :float4,
    701 => :float8,
    774 => :macaddr8,
    829 => :macaddr,
    869 => :inet,
    1_042 => :bpchar,
    1_043 => :varchar,
    1_082 => :date,
    1_083 => :time,
    1_114 => :timestamp,
    1_184 => :timestamptz,
    1_186 => :interval,
    1_266 => :timetz,
    2_950 => :uuid,
    3_802 => :jsonb,
    3_904 => :int4range,
    3_908 => :tsrange,
    3_910 => :tstzrange,
    3_912 => :daterange,
    3_926 => :int8range,
    16_935 => :hstore,
    17_063 => :geometry
  }

  @spec decode(columns :: binary, acc :: list()) :: [struct()]
  def decode(columns, acc \\ [])
  def decode(<<>>, acc), do: Enum.reverse(acc)

  def decode(<<flags::8, rest::binary>>, acc) do
    [
      column_name,
      <<type_oid::32, type_modifier::32, rest::binary>>
    ] = Helper.binary_split(rest)

    decode(
      rest,
      [
        %__MODULE__{
          flags: (flags == 1 && [:key]) || [],
          column_name: column_name,
          type_oid: Map.get(@dict, type_oid, :unknown),
          type_modifier: type_modifier
        }
        | acc
      ]
    )
  end
end
