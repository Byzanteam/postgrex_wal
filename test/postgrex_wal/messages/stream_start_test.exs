defmodule PostgrexWal.Messages.StreamStartTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.StreamStart

  @event <<0, 0, 13, 247, 1>>

  test "decode steam_start message event" do
    assert match?(
             %StreamStart{
               flags: [{:first_segment, true}],
               transaction_id: 3_575
             },
             StreamStart.decode(@event)
           )
  end
end
