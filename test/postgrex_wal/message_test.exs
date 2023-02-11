defmodule PostgrexWal.MessageTest do
  use ExUnit.Case, async: true

  alias PostgrexWal.Message
  alias PostgrexWal.Messages.{Delete, Insert, Update}

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
end
