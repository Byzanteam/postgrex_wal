defmodule PostgrexWal.Messages.RelationTest do
  use ExUnit.Case, async: true
  alias PostgrexWal.Messages.Relation
  alias PostgrexWal.Messages.Relation.Column

  @event <<0, 0, 89, 103, 112, 117, 98, 108, 105, 99, 0, 117, 115, 101, 114, 115, 0, 102, 0, 7, 1,
           105, 100, 0, 0, 0, 0, 20, 255, 255, 255, 255, 1, 110, 97, 109, 101, 0, 0, 0, 4, 19,
           255, 255, 255, 255, 1, 97, 103, 101, 0, 0, 0, 0, 23, 255, 255, 255, 255, 1, 101, 109,
           97, 105, 108, 0, 0, 0, 4, 19, 255, 255, 255, 255, 1, 112, 97, 115, 115, 119, 111, 114,
           100, 95, 100, 105, 103, 101, 115, 116, 0, 0, 0, 4, 19, 255, 255, 255, 255, 1, 115, 97,
           108, 97, 114, 121, 0, 0, 0, 6, 164, 0, 6, 0, 6, 1, 115, 101, 120, 0, 0, 0, 0, 16, 255,
           255, 255, 255>>

  test "decode relation event" do
    assert match?(
             %Relation{
               transaction_id: 22_887,
               columns: [
                 %Column{
                   type_modifier: 4_294_967_295,
                   type_oid: :int8,
                   column_name: "id",
                   flags: [:key]
                 },
                 %Column{
                   type_modifier: 4_294_967_295,
                   type_oid: :varchar,
                   column_name: "name",
                   flags: [:key]
                 },
                 %Column{
                   type_modifier: 4_294_967_295,
                   type_oid: :int4,
                   column_name: "age",
                   flags: [:key]
                 },
                 %Column{
                   type_modifier: 4_294_967_295,
                   type_oid: :varchar,
                   column_name: "email",
                   flags: [:key]
                 },
                 %Column{
                   type_modifier: 4_294_967_295,
                   type_oid: :varchar,
                   column_name: "password_digest",
                   flags: [:key]
                 },
                 %Column{
                   type_modifier: 393_222,
                   type_oid: :unknown,
                   column_name: "salary",
                   flags: [:key]
                 },
                 %Column{
                   type_modifier: 4_294_967_295,
                   type_oid: :bool,
                   column_name: "sex",
                   flags: [:key]
                 }
               ],
               namespace: "ic",
               number_of_columns: 7,
               relation_name: "users",
               relation_oid: 1_886_741_100,
               replica_identity_setting: [setting: :all_columns]
             },
             Relation.decode(@event)
           )
  end
end