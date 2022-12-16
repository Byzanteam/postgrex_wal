defmodule PostgrexWal.Message.Begin do
  @moduledoc """
  A begin message
  """
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :final_lsn, Helper.lsn()
    field :commit_timestamp, Helper.ts()
    field :xid, integer()
  end

  @impl true
  def decode(<<lsn::binary-8, timestamp::64, xid::32>>) do
    %__MODULE__{
      final_lsn: Helper.decode_lsn(lsn),
      commit_timestamp: Helper.decode_timestamp(timestamp),
      xid: xid
    }
  end
end
