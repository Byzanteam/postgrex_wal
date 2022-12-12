defmodule PostgrexWal.Message.Begin do
  @moduledoc """
  A begin message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :final_lsn, integer()
    field :commit_timestamp, integer()
    field :xid, integer()
  end

  def decode(_state) do
    quote location: :keep do
      <<?B, final_lsn::64, commit_timestamp::64, xid::32>> ->
        %unquote(__MODULE__){
          final_lsn: final_lsn,
          commit_timestamp: commit_timestamp,
          xid: xid
        }
    end
  end
end
