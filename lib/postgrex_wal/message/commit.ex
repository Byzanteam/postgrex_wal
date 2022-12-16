defmodule PostgrexWal.Message.Commit do
  @moduledoc """
  A commit message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :flags, []
    field :lsn, Helper.lsn()
    field :end_lsn, Helper.lsn()
    field :commit_timestamp, DateTime.t()
  end

  @impl true
  def decode(<<_flag::8, lsn::binary-8, end_lsn::binary-8, timestamp::64>>) do
    %__MODULE__{
      # _flags alwary is 0 ?
      flags: [],
      lsn: Helper.decode_lsn(lsn),
      end_lsn: Helper.decode_lsn(end_lsn),
      commit_timestamp: Helper.decode_timestamp(timestamp)
    }
  end
end
