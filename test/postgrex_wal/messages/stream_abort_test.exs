defmodule PostgrexWal.Messages.StreamAbortTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.StreamAbort

  @event <<0, 0, 13, 255, 0, 0, 13, 255>>

  test "decode steam_start message event" do
    assert match?(
             %StreamAbort{
               transaction_id: 3_583,
               sub_transaction_id: 3_583
             },
             StreamAbort.decode(@event)
           )
  end
end
