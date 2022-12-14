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

  @callback decode(message :: binary()) :: struct()

  defmacro __using__(_opts) do
    quote do
      @behaviour PostgrexWal.Message
      use TypedStruct
      alias PostgrexWal.Message
      alias PostgrexWal.Messages.Util
    end
  end

  @type tuple_data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}

  alias PostgrexWal.Messages.{
    Begin,
    Commit,
    Delete,
    Insert,
    Message,
    Origin,
    Relation,
    StreamAbort,
    StreamCommit,
    StreamStart,
    StreamStop,
    Truncate,
    Type,
    Update
  }

  @modules %{
    ?A => StreamAbort,
    ?B => Begin,
    ?C => Commit,
    ?D => Delete,
    ?E => StreamStop,
    ?I => Insert,
    ?M => Message,
    ?O => Origin,
    ?R => Relation,
    ?S => StreamStart,
    ?T => Truncate,
    ?U => Update,
    ?Y => Type,
    ?c => StreamCommit
  }

  @spec decode(event :: {:in_transaction, binary()} | binary()) :: struct()
  def decode({:in_transaction, <<key::8, transaction_id::32, payload::binary>>}) do
    decode(<<key::8>> <> payload) |> struct(transaction_id: transaction_id)
  end

  for {key, module} <- @modules do
    def decode(<<unquote(key)::8, payload::binary>>), do: unquote(module).decode(payload)
  end
end
