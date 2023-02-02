defmodule PostgrexWal.Messages.Util do
  @moduledoc false
  alias PostgrexWal.GenMessage

  @pg_epoch ~U[2000-01-01 00:00:00.000000Z]
  @spec decode_timestamp(microsecond_offset :: integer) :: DateTime.t()
  def decode_timestamp(microsecond_offset) when is_integer(microsecond_offset) do
    DateTime.add(@pg_epoch, microsecond_offset, :microsecond)
  end

  @doc """
  LSN (Log Sequence Number) is a pointer to a location in the WAL.

  PostgreSQL uses two representations for the Log Sequence Number (LSN):
  1. Internally, an LSN is a 64-bit integer, representing a byte position in the write-ahead log stream.
     Used internally by PostgreSQL and sent in the XLogData replication messages.

  2. A string of two hexadecimal numbers of up to eight digits each, separated by a slash. e.g. 1/F73E0220.
     This is the form accepted by Postgrex.ReplicationConnection.start_replication/2.
  """
  @spec decode_lsn(lsn :: integer) :: String.t()
  def decode_lsn(lsn) when is_integer(lsn) do
    <<xlog_file_id::32, xlog_offset::32>> = <<lsn::64>>
    Integer.to_string(xlog_file_id, 16) <> "/" <> Integer.to_string(xlog_offset, 16)
  end

  @spec binary_split(binary, integer, binary) :: list(binary)
  def binary_split(binary, parts \\ 2, delimeter \\ <<0>>) do
    String.split(binary, delimeter, parts: parts)
  end

  @spec decode_tuple_data(tuple_data :: binary) :: [GenMessage.tuple_data()]
  def decode_tuple_data(tuple_data) do
    {<<>>, decoded_tuple_data} = split_tuple_data(tuple_data)
    decoded_tuple_data
  end

  @doc """
  https://www.postgresql.org/docs/current/protocol-logicalrep-message-formats.html

  TupleData
  Int16
  Number of columns.

  Next, one of the following submessages appears for each column (except generated columns):

  Byte1('n')
  Identifies the data as NULL value.

  Or

  Byte1('u')
  Identifies unchanged TOASTed value (the actual value is not sent).

  Or

  Byte1('t')
  Identifies the data as text formatted value.

  Or

  Byte1('b')
  Identifies the data as binary formatted value.

  Int32
  Length of the column value.

  Byten
  The value of the column, either in binary or in text format. (As specified in the preceding format byte). n is the above length.
  """

  @spec split_tuple_data(tuple_data :: binary) :: {binary, [GenMessage.tuple_data()]}
  def split_tuple_data(<<number_of_columns::16, data::binary>>) do
    do_decode(data, number_of_columns, [])
  end

  defp do_decode(remaining_data, 0, acc) do
    {remaining_data, acc |> Enum.reverse()}
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

  @doc "Namespace (empty string for pg_catalog)."
  @spec decode_namespace(binary) :: binary
  def decode_namespace(""), do: "pg_catalog"
  def decode_namespace(namespace), do: namespace

  @replica_identity_settings %{
    ?d => :default,
    ?n => :nothing,
    ?f => :all_columns,
    ?i => :index
  }

  @spec decode_replica_identity_setting(integer) :: atom
  for {key, name} <- @replica_identity_settings do
    def decode_replica_identity_setting(unquote(key)), do: unquote(name)
  end
end
