defmodule PostgrexWal.Messages.BeginTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Begin

  @event <<0, 0, 0, 0, 2, 227, 251, 232, 0, 2, 146, 234, 159, 209, 83, 66, 0, 0, 13, 247>>
  test "decode begin event" do
    assert match?(
             %Begin{
               transaction_id: 3_575,
               commit_timestamp: ~U[2022-12-16 06:12:34.719554Z],
               final_lsn: "0/2E3FBE8"
             },
             Begin.decode(@event)
           )
  end
end
