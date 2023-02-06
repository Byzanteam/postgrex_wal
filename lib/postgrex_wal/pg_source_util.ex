defmodule PostgrexWal.PgSourceUtil do
  @moduledoc """
  PgSource auxiliary functions
  """

  require Logger
  alias PostgrexWal.PgSource

  @doc """
  The logical replication protocol sends individual transactions one by one.
  This means that all messages between a pair of Begin and Commit messages belong to the same transaction.
  It also sends changes of large in-progress transactions between a pair of Stream Start and Stream Stop messages.
  The last stream of such a transaction contains Stream Commit or Stream Abort message.
  """

  @modules %{
    Begin => ?B,
    Commit => ?C,
    Delete => ?D,
    Insert => ?I,
    Message => ?M,
    Origin => ?O,
    Relation => ?R,
    StreamAbort => ?A,
    StreamCommit => ?c,
    StreamStart => ?S,
    StreamStop => ?E,
    Truncate => ?T,
    Type => ?Y,
    Update => ?U
  }
  @stream_start @modules[StreamStart]
  @stream_stop @modules[StreamStop]

  @spec decode_wal(binary(), PgSource.t()) :: {struct(), PgSource.t()}
  def decode_wal(<<@stream_start::8, _rest::binary>> = event, state) do
    if state.in_stream?, do: Logger.error("stream flag consecutively true")
    {decode(event), %{state | in_stream?: true}}
  end

  def decode_wal(<<@stream_stop::8, _rest::binary>> = event, state) do
    unless state.in_stream?, do: Logger.error("stream flag consecutively false")
    {decode(event), %{state | in_stream?: false}}
  end

  @streamable_modules [Delete, Insert, Message, Relation, Truncate, Type, Update]
  @streamable_keys @modules |> Map.take(@streamable_modules) |> Map.values()
  def decode_wal(<<key::8, transaction_id::32, rest::binary>>, %{in_stream?: true} = state)
      when key in @streamable_keys do
    message = decode(<<key::8>> <> rest) |> struct!(transaction_id: transaction_id)
    {message, state}
  end

  def decode_wal(event, state) do
    {decode(event), state}
  end

  for {module, key} <- @modules do
    m = Module.concat(PostgrexWal.Messages, module)
    defp decode(<<unquote(key)::8, payload::binary>>), do: unquote(m).decode(payload)
  end
end
