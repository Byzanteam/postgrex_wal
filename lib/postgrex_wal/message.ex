defmodule PostgrexWal.Message do
  @moduledoc """
  Logical Streaming Replication Protocol
  https://www.postgresql.org/docs/15/protocol-logical-replication.html

  Protocol version. Currently versions 1, 2, and 3 are supported.
  Version 2 is supported only for server version 14 and above, and it allows streaming of large in-progress transactions.
  Version 3 is supported only for server version 15 and above, and it allows streaming of two-phase commits.

  reference:
  https://www.postgresql.org/docs/15/logicaldecoding-walsender.html
  https://www.postgresql.org/docs/current/protocol-logicalrep-message-formats.html
  """

  require Logger
  alias PostgrexWal.StreamBoundaryError

  @modules %{
    Begin: ?B,
    Commit: ?C,
    Delete: ?D,
    Insert: ?I,
    Message: ?M,
    Origin: ?O,
    Relation: ?R,
    StreamAbort: ?A,
    StreamCommit: ?c,
    StreamStart: ?S,
    StreamStop: ?E,
    Truncate: ?T,
    Type: ?Y,
    Update: ?U
  }

  @module_prefix PostgrexWal.Messages
  @streamable_modules [:Delete, :Insert, :Message, :Relation, :Truncate, :Type, :Update]
  @stream_start_key @modules[:StreamStart]
  @stream_stop_key @modules[:StreamStop]
  @streamable_keys @modules |> Map.take(@streamable_modules) |> Map.values()

  expr =
    for {m, _} <- @modules, module = Module.concat(@module_prefix, m), reduce: nil do
      nil -> quote do: unquote(module).t()
      acc -> quote do: unquote(module).t() | unquote(acc)
    end

  @type t() :: unquote(expr)
  @type tuple_data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}
  @type event() :: binary()

  @callback decode(event()) :: t()

  defmacro __using__(_opts) do
    quote do
      @behaviour PostgrexWal.Message
      use TypedStruct
      alias PostgrexWal.{Message, MessageUtil}
    end
  end

  @spec decode(event()) :: t()
  for {module, key} <- @modules do
    m = Module.concat(@module_prefix, module)
    def decode(<<unquote(key), payload::binary>>), do: unquote(m).decode(payload)
  end

  @doc """
  The logical replication protocol sends individual transactions one by one.
  This means that all messages between a pair of Begin and Commit messages belong to the same transaction.
  It also sends changes of large in-progress transactions between a pair of Stream Start and Stream Stop messages.
  The last stream of such a transaction contains Stream Commit or Stream Abort message.
  """

  @type state() :: PostgrexWal.PgSource.t()
  @spec decode_wal(event(), state()) :: {t(), state()}
  def decode_wal(<<@stream_start_key, _rest::binary>> = event, state) do
    if state.in_stream?, do: raise(StreamBoundaryError, "adjacent true")
    {decode(event), %{state | in_stream?: true}}
  end

  def decode_wal(<<@stream_stop_key, _rest::binary>> = event, state) do
    unless state.in_stream?, do: raise(StreamBoundaryError, "adjacent false")
    {decode(event), %{state | in_stream?: false}}
  end

  def decode_wal(<<key, transaction_id::32, rest::binary>>, %{in_stream?: true} = state)
      when key in @streamable_keys do
    {
      decode(<<key>> <> rest) |> struct!(transaction_id: transaction_id),
      state
    }
  end

  def decode_wal(event, state), do: {decode(event), state}
end
