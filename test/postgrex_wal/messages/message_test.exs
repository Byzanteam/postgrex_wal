defmodule PostgrexWal.Messages.MessageTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Message

  @event <<0, 0, 0, 0, 0, 2, 227, 251, 232, 109, 121, 95, 116, 101, 115, 116, 0, 0, 0, 0, 4, 116,
           101, 115, 116>>

  test "decode message event" do
    assert match?(
             %Message{
               transaction_id: nil,
               content: "test",
               flags: [transactional: false],
               lsn: "0/2E3FBE8",
               prefix: "my_test"
             },
             Message.decode(@event)
           )
  end
end
