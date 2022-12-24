defmodule PostgrexWal.Messages.StreamCommitTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.StreamCommit

  @event <<0, 0, 13, 247, 0, 0, 0, 0, 0, 2, 227, 251, 232, 0, 0, 0, 0, 2, 227, 251, 245, 0, 2,
           146, 234, 159, 209, 83, 66>>

  test "decode steam_start message event" do
    assert match?(
             %StreamCommit{
               transaction_id: 3_575,
               commit_timestamp: ~U[2022-12-16 06:12:34.719554Z],
               end_lsn: {0, 48_495_605},
               flags: [],
               lsn: {0, 48_495_592}
             },
             StreamCommit.decode(@event)
           )
  end
end
