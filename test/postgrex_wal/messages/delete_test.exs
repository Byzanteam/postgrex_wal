defmodule PostgrexWal.Messages.DeleteTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Delete

  @event <<0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 48, 50, 57, 116, 0,
           0, 0, 8, 116, 105, 116, 108, 101, 50, 50, 50, 116, 0, 0, 0, 1, 50, 110, 110, 110, 110>>

  test "decode begin event" do
    assert match?(
             %Delete{
               transaction_id: nil,
               changed_key_tuple_data: nil,
               old_tuple_data:
                 {{:text, "980191029"}, {:text, "title222"}, {:text, "2"}, nil, nil, nil, nil},
               relation_oid: 22_887
             },
             Delete.decode(@event)
           )
  end
end
