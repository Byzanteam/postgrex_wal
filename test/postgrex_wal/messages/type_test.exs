defmodule PostgrexWal.Messages.TypeTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Type
  @event <<0, 0, 121, 228, 112, 117, 98, 108, 105, 99, 0, 109, 121, 95, 116, 121, 112, 101, 0>>

  test "decode type event" do
    assert match?(
             %Type{
               transaction_id: nil,
               namespace: "public",
               type_name: "my_type",
               type_oid: 31_204
             },
             Type.decode(@event)
           )
  end

  test "decode steamed type event" do
    assert match?(
             %Type{
               transaction_id: 123,
               namespace: "public",
               type_name: "my_type",
               type_oid: 31_204
             },
             PostgrexWal.Message.decode({:in_stream, <<?Y, 123::32, @event>>})
           )
  end
end
