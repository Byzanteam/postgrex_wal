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

  @spec decode(key :: integer, event :: binary, in_transaction :: boolean()) :: struct()
  def decode(key, <<transaction_id::32, payload::binary>> = event, in_transaction \\ false) do
    module = Map.fetch!(@modules, key)

    if in_transaction do
      module.decode(payload) |> struct(transaction_id: transaction_id)
    else
      module.decode(event)
    end
  end
end
