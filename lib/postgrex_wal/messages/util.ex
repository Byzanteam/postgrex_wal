defmodule PostgrexWal.Messages.Util do
  @moduledoc false

  @spec decode_lsn(lsn :: binary) :: {integer, integer}
  def decode_lsn(<<xlog_file::32, xlog_offset::32>>), do: {xlog_file, xlog_offset}

  @pg_epoch ~U[2000-01-01 00:00:00Z]
  @spec decode_timestamp(microsecond_offset :: integer) :: DateTime.t()
  def decode_timestamp(microsecond_offset) when is_integer(microsecond_offset) do
    DateTime.add(@pg_epoch, microsecond_offset, :microsecond)
  end

  @spec binary_split(binary, integer, binary) :: list(binary)
  def binary_split(binary, parts \\ 2, delimeter \\ <<0>>) do
    String.split(binary, delimeter, parts: parts)
  end

  @spec decode_tuple_data!(tuple_data :: binary) :: tuple
  def decode_tuple_data!(tuple_data) do
    {<<>>, decoded_tuple_data} = decode_tuple_data(tuple_data)
    decoded_tuple_data
  end

  @spec decode_tuple_data(binary) :: tuple
  def decode_tuple_data(<<number_of_columns::16, data::binary>>) do
    do_decode(data, number_of_columns, [])
  end

  defp do_decode(remaining_data, 0, acc) do
    {remaining_data, acc |> Enum.reverse() |> List.to_tuple()}
  end

  defp do_decode(<<?n, rest::binary>>, columns_remaining, acc) do
    do_decode(rest, columns_remaining - 1, [nil | acc])
  end

  defp do_decode(<<?u, rest::binary>>, columns_remaining, acc) do
    do_decode(rest, columns_remaining - 1, [:unchanged_toast | acc])
  end

  defp do_decode(
         <<?t, n::32, text::binary-size(n), rest::binary>>,
         columns_remaining,
         acc
       ) do
    do_decode(rest, columns_remaining - 1, [{:text, text} | acc])
  end

  defp do_decode(
         <<?b, n::32, binary::binary-size(n), rest::binary>>,
         columns_remaining,
         acc
       ) do
    do_decode(rest, columns_remaining - 1, [{:binary, binary} | acc])
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
  @spec decode_type_oid(type_oid :: integer) :: atom
  for {type_oid, type_name} <- @dict do
    def decode_type_oid(unquote(type_oid)), do: unquote(type_name)
  end

  def decode_type_oid(_), do: :unknown
end
