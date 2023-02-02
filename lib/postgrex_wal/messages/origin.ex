defmodule PostgrexWal.Messages.Origin do
  @moduledoc """
  Every sent transaction contains zero or more DML messages (Insert, Update, Delete).
  In case of a cascaded setup it can also contain Origin messages.
  The origin message indicates that the transaction originated on different replication node.
  Since a replication node in the scope of logical replication protocol can be pretty much anything, the only identifier is the origin name.
  It's downstream's responsibility to handle this as needed (if needed). The Origin message is always sent before any DML messages in the transaction.
  """

  use PostgrexWal.GenMessage

  typedstruct enforce: true do
    field :commit_lsn, String.t()
    field :name, String.t()
  end

  @doc """
  A Origin message

  Byte1('O')
  Identifies the message as an origin message.

  Int64 (XLogRecPtr)
  The LSN of the commit on the origin server.

  String
  Name of the origin.

  Note that there can be multiple Origin messages inside a single transaction.
  """
  @impl true
  def decode(<<lsn::64, name::binary>>) do
    %__MODULE__{
      commit_lsn: Util.decode_lsn(lsn),
      name: String.trim_trailing(name, "\0")
    }
  end

  @impl true
  def identifier, do: ?O
end
