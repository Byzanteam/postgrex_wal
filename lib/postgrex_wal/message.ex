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

  @type t() ::
          Begin.t()
          | Commit.t()
          | Delete.t()
          | Insert.t()
          | Message.t()
          | Origin.t()
          | Relation.t()
          | StreamAbort.t()
          | StreamCommit.t()
          | StreamStart.t()
          | StreamStop.t()
          | Truncate.t()
          | Type.t()
          | Update.t()

  @type tuple_data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}

  @callback decode(binary()) :: t()

  defmacro __using__(_opts) do
    quote do
      @behaviour PostgrexWal.Message
      use TypedStruct
      alias PostgrexWal.{Message, MessageUtil}
    end
  end
end
