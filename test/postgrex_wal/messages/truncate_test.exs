defmodule PostgrexWal.Messages.TruncateTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Truncate

  @event <<0, 0, 0, 1, 0, 0, 0, 89, 103>>

  test "decode truncate event" do
    assert match?(
             %Truncate{
               transaction_id: nil,
               number_of_relations: 1,
               options: [truncate: []],
               relation_oids: [22_887]
             },
             Truncate.decode(@event)
           )
  end
end
