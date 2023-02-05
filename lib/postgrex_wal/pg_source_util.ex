defmodule PostgrexWal.PgSourceUtil do
  @moduledoc """
  PgSource auxiliary functions
  """

  require Logger

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

  @doc """
  The logical replication protocol sends individual transactions one by one.
  This means that all messages between a pair of Begin and Commit messages belong to the same transaction.
  It also sends changes of large in-progress transactions between a pair of Stream Start and Stream Stop messages.
  The last stream of such a transaction contains Stream Commit or Stream Abort message.
  """

  @stream_start @modules[StreamStart]
  @stream_stop @modules[StreamStop]
  @spec decode_wal(binary(), PostgrexWal.PgSource.t()) :: {struct(), PostgrexWal.PgSource.t()}
  def decode_wal(<<key::8, rest::binary>> = event, state) do
    in_stream? =
      case key do
        @stream_start ->
          state.in_stream? && Logger.error("stream flag consecutively true")
          true

        @stream_stop ->
          state.in_stream? || Logger.error("stream flag consecutively false")
          false

        _ ->
          state.in_stream?
      end

    message =
      if in_stream? and streamable?(key) do
        <<transaction_id::32, rest::binary>> = rest
        decode(<<key::8>> <> rest) |> struct(transaction_id: transaction_id)
      else
        decode(event)
      end

    {message, %{state | in_stream?: in_stream?}}
  end

  for {module, key} <- @modules do
    m = Module.concat(PostgrexWal.Messages, module)
    defp decode(<<unquote(key)::8, payload::binary>>), do: unquote(m).decode(payload)
  end

  @streamable_modules [Delete, Insert, Message, Relation, Truncate, Type, Update]
  for {_module, key} <- Map.take(@modules, @streamable_modules) do
    defp streamable?(unquote(key)), do: true
  end

  defp streamable?(_key), do: false
end
