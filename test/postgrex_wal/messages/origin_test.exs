defmodule PostgrexWal.Messages.OriginTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Origin
  @event <<0, 0, 0, 0, 2, 227, 251, 232, 109, 121, 95, 111, 114, 105, 103, 105, 110, 0>>

  test "decode begin event" do
    assert match?(
             %Origin{
               name: "my_origin",
               commit_lsn: "0/2E3FBE8"
             },
             Origin.decode(@event)
           )
  end
end
