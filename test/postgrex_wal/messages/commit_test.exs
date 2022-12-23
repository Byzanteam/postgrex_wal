defmodule PostgrexWal.Messages.CommitTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Commit

  @event <<0, 0, 0, 0, 0, 2, 227, 251, 232, 0, 0, 0, 0, 2, 227, 252, 24, 0, 2, 146, 234, 159, 209,
           83, 66>>

  test "decode commit event" do
    assert match?(
             %Commit{
               commit_timestamp: ~U[2022-12-16 06:12:34.719554Z],
               end_lsn: {0, 48_495_640},
               lsn: {0, 48_495_592},
               flags: []
             },
             Commit.decode(@event)
           )
  end
end
