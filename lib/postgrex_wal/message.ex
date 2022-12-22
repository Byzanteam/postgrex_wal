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

  @type lsn() :: {integer(), integer()}
  @type tuple_data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}

  alias PostgrexWal.Messages.{
    Begin,
    Commit,
    Delete,
    Insert,
    Origin,
    Relation,
    Truncate,
    Type,
    Update
  }

  @modules %{
    ?B => Begin,
    ?C => Commit,
    ?D => Delete,
    ?I => Insert,
    ?O => Origin,
    ?R => Relation,
    ?T => Truncate,
    ?Y => Type,
    ?U => Update
  }

  for {key, module} <- @modules do
    def decode(<<unquote(key), payload::binary>>), do: unquote(module).decode(payload)
  end
end
