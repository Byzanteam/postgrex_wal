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

  @doc """
  The logical replication protocol sends individual transactions one by one.
  This means that all messages between a pair of Begin and Commit messages belong to the same transaction.
  It also sends changes of large in-progress transactions between a pair of Stream Start and Stream Stop messages.
  The last stream of such a transaction contains Stream Commit or Stream Abort message.
  """

  @spec decode(event :: {:in_transaction, binary()} | binary()) :: struct()
  def decode({:in_stream, <<key::8, transaction_id::32, payload::binary>>}) do
    decode(<<key::8>> <> payload) |> struct(transaction_id: transaction_id)
  end

  @modules [
    StreamAbort,
    Begin,
    Commit,
    Delete,
    StreamStop,
    Insert,
    Message,
    Origin,
    Relation,
    StreamStart,
    Truncate,
    Update,
    Type,
    StreamCommit
  ]

  for m <- @modules do
    def decode(<<unquote(m.identifier())::8, payload::binary>>), do: unquote(m).decode(payload)
  end

  @spec stream_start?(byte()) :: boolean()
  def stream_start?(key) do
    key === StreamStart.identifier()
  end

  @spec stream_stop?(byte()) :: boolean()
  def stream_stop?(key) do
    key === StreamStop.identifier()
  end

  @streamable_modules [
    Delete,
    Insert,
    Message,
    Relation,
    Truncate,
    Update,
    Type
  ]

  @spec streamable?(byte()) :: boolean()
  def streamable?(key) do
    key in for m <- @streamable_modules, do: m.identifier()
  end
end
