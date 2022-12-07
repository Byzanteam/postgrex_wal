defmodule PostgrexWal.Message.Begin do
  @moduledoc """
  A begin message
  """
  use TypedStruct

  typedstruct enforce: true do
    field :final_lsn, integer()
    field :commit_timestamp, integer()
    field :xid, integer()
  end

  def decode(<<final_lsn::64, commit_timestamp::64, xid::32>>) do
    %__MODULE__{
      final_lsn: final_lsn,
      commit_timestamp: commit_timestamp,
      xid: xid
    }
  end
end
