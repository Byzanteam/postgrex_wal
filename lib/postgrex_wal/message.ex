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

  expr =
    @modules
    |> Enum.map(fn {module, _key} ->
      m = Module.concat(@module_prefix, module)
      quote do: unquote(m).t()
    end)
    |> Enum.reduce(fn type, acc ->
      quote do: unquote(type) | unquote(acc)
    end)

  @type t() :: unquote(expr)
  @type tuple_data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}

  @callback decode(event) :: message when event: binary(), message: t()

  defmacro __using__(_opts) do
    quote do
      @behaviour PostgrexWal.Message
      use TypedStruct
      alias PostgrexWal.{Message, MessageUtil}
    end
  end

  def stream_start_key, do: @modules[:StreamStart]
  def stream_stop_key, do: @modules[:StreamStop]
  def streamable_keys, do: @modules |> Map.take(@streamable_modules) |> Map.values()

  @spec decode(event) :: message when event: binary(), message: t()
  for {module, key} <- @modules do
    m = Module.concat(@module_prefix, module)
    def decode(<<unquote(key), payload::binary>>), do: unquote(m).decode(payload)
  end
end
