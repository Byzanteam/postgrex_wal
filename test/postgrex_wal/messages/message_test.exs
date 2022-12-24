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
               lsn: {0, 48_495_592},
               prefix: "my_test"
             },
             Message.decode(@event)
           )
  end

  test "decode steamed message event" do
    assert match?(
             %Message{
               content: "test",
               flags: [transactional: false],
               lsn: {0, 48_495_592},
               prefix: "my_test",
               transaction_id: 123
             },
             Message.decode(<<"stream", 123::32, @event>>)
           )
  end
end
