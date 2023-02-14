defmodule PostgrexWal.MessageTest do
  use ExUnit.Case, async: true

  alias PostgrexWal.Message
  alias PostgrexWal.Messages.{Delete, Insert, Type, Update}

  @event <<?I, 0, 0, 89, 103, 78, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116,
           0, 0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 49, 49, 110, 110, 110, 110>>

  test "decode insert event" do
    assert match?(
             %Insert{
               transaction_id: nil,
               relation_oid: 22_887,
               tuple_data: [
                 {:text, "980191253"},
                 {:text, "abc"},
                 {:text, "11"},
                 nil,
                 nil,
                 nil,
                 nil
               ]
             },
             Message.decode(@event)
           )
  end

  @event <<?D, 0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 48, 50, 57, 116,
           0, 0, 0, 8, 116, 105, 116, 108, 101, 50, 50, 50, 116, 0, 0, 0, 1, 50, 110, 110, 110,
           110>>

  test "decode delete event(?O)" do
    assert match?(
             %Delete{
               transaction_id: nil,
               changed_key_tuple_data: nil,
               old_tuple_data: [
                 {:text, "980191029"},
                 {:text, "title222"},
                 {:text, "2"},
                 nil,
                 nil,
                 nil,
                 nil
               ],
               relation_oid: 22_887
             },
             Message.decode(@event)
           )
  end

  @event <<?U, 0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116,
           0, 0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 49, 49, 110, 110, 110, 110, 78, 0, 7, 116, 0,
           0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116, 0, 0, 0, 3, 100, 101, 102, 116, 0, 0,
           0, 2, 50, 50, 110, 110, 110, 110>>

  test "decode update event(?O)" do
    assert match?(
             %Update{
               relation_oid: 22_887,
               changed_key_tuple_data: nil,
               old_tuple_data: [
                 {:text, "980191253"},
                 {:text, "abc"},
                 {:text, "11"},
                 nil,
                 nil,
                 nil,
                 nil
               ],
               transaction_id: nil,
               tuple_data: [
                 {:text, "980191253"},
                 {:text, "def"},
                 {:text, "22"},
                 nil,
                 nil,
                 nil,
                 nil
               ]
             },
             Message.decode(@event)
           )
  end

  @delete_event <<?D, 123::32, 0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49,
                  48, 50, 57, 116, 0, 0, 0, 8, 116, 105, 116, 108, 101, 50, 50, 50, 116, 0, 0, 0,
                  1, 50, 110, 110, 110, 110>>

  test "decode steamed delete event" do
    {message, _state} = Message.decode_wal(@delete_event, %{in_stream?: true})

    assert match?(
             %Delete{
               changed_key_tuple_data: nil,
               old_tuple_data: [
                 {:text, "980191029"},
                 {:text, "title222"},
                 {:text, "2"},
                 nil,
                 nil,
                 nil,
                 nil
               ],
               relation_oid: 22_887,
               transaction_id: 123
             },
             message
           )
  end

  @message_event <<?M, 123::32, 0, 0, 0, 0, 0, 2, 227, 251, 232, 109, 121, 95, 116, 101, 115, 116,
                   0, 0, 0, 0, 4, 116, 101, 115, 116>>

  test "decode steamed message event" do
    {message, _state} = Message.decode_wal(@message_event, %{in_stream?: true})

    assert match?(
             %PostgrexWal.Messages.Message{
               content: "test",
               flags: [transactional: false],
               lsn: "0/2E3FBE8",
               prefix: "my_test",
               transaction_id: 123
             },
             message
           )
  end

  @type_event <<?Y, 123::32, 0, 0, 121, 228, 112, 117, 98, 108, 105, 99, 0, 109, 121, 95, 116,
                121, 112, 101, 0>>

  test "decode steamed type event" do
    {message, _state} = Message.decode_wal(@type_event, %{in_stream?: true})

    assert match?(
             %Type{
               transaction_id: 123,
               namespace: "public",
               type_name: "my_type",
               type_oid: 31_204
             },
             message
           )
  end
end
