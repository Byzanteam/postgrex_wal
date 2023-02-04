defmodule PostgrexWal.PgSourceUtil do
  @moduledoc """
  PgSource auxiliary functions
  """

  require Logger

  @modules %{
    StreamAbort => ?A,
    Begin => ?B,
    Commit => ?C,
    Delete => ?D,
    StreamStop => ?E,
    Insert => ?I,
    Message => ?M,
    Origin => ?O,
    Relation => ?R,
    StreamStart => ?S,
    Truncate => ?T,
    Update => ?U,
    Type => ?Y,
    StreamCommit => ?c
  }

  @doc """
  The logical replication protocol sends individual transactions one by one.
  This means that all messages between a pair of Begin and Commit messages belong to the same transaction.
  It also sends changes of large in-progress transactions between a pair of Stream Start and Stream Stop messages.
  The last stream of such a transaction contains Stream Commit or Stream Abort message.
  """

  def decode_wal(<<key::8, _rest::binary>> = payload, state) do
    {stream_start, stream_stop} = {@modules[StreamStart], @modules[StreamStop]}

    in_stream? =
      case key do
        ^stream_start ->
          state.in_stream? && Logger.error("stream flag consecutively true")
          true

        ^stream_stop ->
          state.in_stream? || Logger.error("stream flag consecutively false")
          false

        _ ->
          state.in_stream?
      end

    payload =
      if in_stream? and streamable?(key),
        do: {:in_stream, payload},
        else: payload

    {decode(payload), %{state | in_stream?: in_stream?}}
  end

  def decode({:in_stream, <<key::8, transaction_id::32, payload::binary>>}) do
    decode(<<key::8>> <> payload) |> struct(transaction_id: transaction_id)
  end

  for {module, key} <- @modules do
    m = Module.concat(PostgrexWal.Messages, module)
    def decode(<<unquote(key)::8, payload::binary>>), do: unquote(m).decode(payload)
  end

  @streamable_modules [Delete, Insert, Message, Relation, Truncate, Update, Type]

  for {_module, key} <- Map.take(@modules, @streamable_modules) do
    defp streamable?(unquote(key)), do: true
  end

  defp streamable?(_key), do: false
end
