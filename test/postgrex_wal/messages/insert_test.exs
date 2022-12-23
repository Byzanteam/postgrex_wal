defmodule PostgrexWal.Messages.InsertTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Insert

  @event <<0, 0, 89, 103, 78, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116, 0,
           0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 49, 49, 110, 110, 110, 110>>

  test "decode insert event" do
    assert match?(
             %Insert{
               transaction_id: nil,
               relation_oid: 22_887,
               tuple_data:
                 {{:text, "980191253"}, {:text, "abc"}, {:text, "11"}, nil, nil, nil, nil}
             },
             Insert.decode(@event)
           )
  end
end
