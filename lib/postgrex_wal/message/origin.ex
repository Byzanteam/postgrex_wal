defmodule PostgrexWal.Message.Origin do
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
    field :origin_commit_lsn, Helper.lsn()
    field :name, String.t()
  end

  @impl true
  def decode(<<lsn::binary-8, name::binary>>) do
    %__MODULE__{
      origin_commit_lsn: Helper.decode_lsn(lsn),
      name: name
    }
  end
end
