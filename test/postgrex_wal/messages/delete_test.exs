defmodule PostgrexWal.Messages.DeleteTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Delete

  @event <<0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 48, 50, 57, 116, 0,
           0, 0, 8, 116, 105, 116, 108, 101, 50, 50, 50, 116, 0, 0, 0, 1, 50, 110, 110, 110, 110>>

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
             Delete.decode(@event)
           )
  end

  @event <<0, 0, 89, 103, 75, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 48, 50, 57, 116, 0,
           0, 0, 8, 116, 105, 116, 108, 101, 50, 50, 50, 116, 0, 0, 0, 1, 50, 110, 110, 110, 110>>

  test "decode delete event(?K)" do
    assert match?(
             %Delete{
               changed_key_tuple_data: [
                 {:text, "980191029"},
                 {:text, "title222"},
                 {:text, "2"},
                 nil,
                 nil,
                 nil,
                 nil
               ],
               old_tuple_data: nil,
               relation_oid: 22_887,
               transaction_id: nil
             },
             Delete.decode(@event)
           )
  end

  test "decode steamed delete event" do
    assert match?(
             %Delete{
               changed_key_tuple_data: [
                 {:text, "980191029"},
                 {:text, "title222"},
                 {:text, "2"},
                 nil,
                 nil,
                 nil,
                 nil
               ],
               old_tuple_data: nil,
               relation_oid: 22_887,
               transaction_id: 123
             },
             PostgrexWal.Message.decode(?D, <<123::32, @event>>, true)
           )
  end
end
