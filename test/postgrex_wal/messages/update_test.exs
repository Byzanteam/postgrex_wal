defmodule PostgrexWal.Messages.UpdateTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Update

  @event <<0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116, 0,
           0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 49, 49, 110, 110, 110, 110, 78, 0, 7, 116, 0, 0,
           0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116, 0, 0, 0, 3, 100, 101, 102, 116, 0, 0, 0,
           2, 50, 50, 110, 110, 110, 110>>

  test "decode commit event" do
    assert match?(
             %Update{
               relation_oid: 22_887,
               changed_key_tuple_data: nil,
               old_tuple_data:
                 {{:text, "980191253"}, {:text, "abc"}, {:text, "11"}, nil, nil, nil, nil},
               transaction_id: nil,
               tuple_data:
                 {{:text, "980191253"}, {:text, "def"}, {:text, "22"}, nil, nil, nil, nil}
             },
             Update.decode(@event)
           )
  end
end
