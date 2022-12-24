defmodule PostgrexWal.Messages.Origin do
  @moduledoc """
  A Origin message

  Byte1('O')
  Identifies the message as an origin message.

  Int64 (XLogRecPtr)
  The LSN of the commit on the origin server.

  String
  Name of the origin.

  Note that there can be multiple Origin messages inside a single transaction.
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :commit_lsn, Message.lsn()
    field :name, String.t()
  end

  @impl true
  def decode(<<lsn::binary-8, name::binary>>) do
    %__MODULE__{
      commit_lsn: Util.decode_lsn(lsn),
      name: String.trim_trailing(name, "\0")
    }
  end
end
