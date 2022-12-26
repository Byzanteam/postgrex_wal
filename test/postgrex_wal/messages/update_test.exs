defmodule PostgrexWal.Messages.UpdateTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Update

  @event <<0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116, 0,
           0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 49, 49, 110, 110, 110, 110, 78, 0, 7, 116, 0, 0,
           0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 51, 116, 0, 0, 0, 3, 100, 101, 102, 116, 0, 0, 0,
           2, 50, 50, 110, 110, 110, 110>>

  test "decode update event" do
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
             Update.decode(@event)
           )
  end

  # NOTE:
  # UPDATE "users" SET "salary" = $1, "sex" = $2, "emo" = $3 WHERE "users"."id" = $4
  # [["salary", "12.34"], ["sex", true], ["emo", "add emo text"], ["id", 1]]
  @event <<0, 0, 122, 7, 79, 0, 8, 116, 0, 0, 0, 1, 49, 116, 0, 0, 0, 3, 97, 98, 99, 116, 0, 0, 0,
           2, 50, 50, 110, 116, 0, 0, 0, 60, 36, 50, 97, 36, 49, 50, 36, 115, 107, 53, 77, 118,
           105, 116, 121, 51, 102, 67, 70, 56, 78, 47, 77, 67, 98, 67, 86, 103, 46, 115, 117, 70,
           51, 78, 114, 57, 103, 82, 52, 46, 57, 99, 102, 74, 73, 105, 120, 53, 71, 104, 53, 83,
           86, 104, 117, 46, 115, 122, 110, 83, 110, 110, 110, 78, 0, 8, 116, 0, 0, 0, 1, 49, 116,
           0, 0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 50, 110, 116, 0, 0, 0, 60, 36, 50, 97, 36,
           49, 50, 36, 115, 107, 53, 77, 118, 105, 116, 121, 51, 102, 67, 70, 56, 78, 47, 77, 67,
           98, 67, 86, 103, 46, 115, 117, 70, 51, 78, 114, 57, 103, 82, 52, 46, 57, 99, 102, 74,
           73, 105, 120, 53, 71, 104, 53, 83, 86, 104, 117, 46, 115, 122, 110, 83, 116, 0, 0, 0,
           5, 49, 50, 46, 51, 52, 116, 0, 0, 0, 1, 116, 116, 0, 0, 0, 12, 97, 100, 100, 32, 101,
           109, 111, 32, 116, 101, 120, 116>>

  test "decode users_one_row_update event" do
    assert match?(
             %Update{
               changed_key_tuple_data: nil,
               old_tuple_data: [
                 {:text, "1"},
                 {:text, "abc"},
                 {:text, "22"},
                 nil,
                 {:text, "$2a$12$sk5Mvity3fCF8N/MCbCVg.suF3Nr9gR4.9cfJIix5Gh5SVhu.sznS"},
                 nil,
                 nil,
                 nil
               ],
               relation_oid: 31_239,
               transaction_id: nil,
               tuple_data: [
                 {:text, "1"},
                 {:text, "abc"},
                 {:text, "22"},
                 nil,
                 {:text, "$2a$12$sk5Mvity3fCF8N/MCbCVg.suF3Nr9gR4.9cfJIix5Gh5SVhu.sznS"},
                 {:text, "12.34"},
                 {:text, "t"},
                 {:text, "add emo text"}
               ]
             },
             Update.decode(@event)
           )
  end
end
