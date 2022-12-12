defmodule PostgrexWal.Message.Commit do
  @moduledoc """
  A commit message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :lsn, integer()
    field :end_lsn, integer()
    field :commit_timestamp, integer()
  end

  @impl true
  def decode(<<0::8, lsn::64, end_lsn::64, commit_timestamp::64>>) do
    %__MODULE__{
      lsn: lsn,
      end_lsn: end_lsn,
      commit_timestamp: commit_timestamp
    }
  end
end
