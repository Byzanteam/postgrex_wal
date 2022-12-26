defmodule PostgrexWal.Messages.StreamStopTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.StreamStop

  @event <<>>

  test "decode steam_start message event" do
    assert match?(
             %StreamStop{},
             StreamStop.decode(@event)
           )
  end
end
