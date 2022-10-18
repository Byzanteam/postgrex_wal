defmodule PostgrexWal.Message.TupleData do
  @moduledoc false

  @typep data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}

  @spec decode(binary()) :: [data()]
  def decode(<<_number_of_columns::16, data::binary>>) do
    do_decode(data, [])
  end

  def do_decode(<<>>, accumulator), do: Enum.reverse(accumulator)

  def do_decode(<<?n, rest::binary>>, accumulator), do: do_decode(rest, [nil | accumulator])

  def do_decode(<<?u, rest::binary>>, accumulator),
    do: do_decode(rest, [:unchanged_toast | accumulator])

  def do_decode(<<?t, n::32, text::binary-size(n), rest::binary>>, accumulator),
    do: do_decode(rest, [{:text, text} | accumulator])

  def do_decode(<<?b, n::32, binary::binary-size(n), rest::binary>>, accumulator),
    do: do_decode(rest, [{:binary, binary} | accumulator])
end
