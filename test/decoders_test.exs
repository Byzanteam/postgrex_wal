defmodule DecodersTest do
  @binary_events %{
    Begin: <<66, 0, 0, 0, 0, 2, 227, 251, 232, 0, 2, 146, 234, 159, 209, 83, 66, 0, 0, 13, 247>>,
    Commit:
      <<67, 0, 0, 0, 0, 0, 2, 227, 251, 232, 0, 0, 0, 0, 2, 227, 252, 24, 0, 2, 146, 234, 159,
        209, 83, 66>>,
    Relation:
      <<82, 0, 0, 89, 103, 112, 117, 98, 108, 105, 99, 0, 117, 115, 101, 114, 115, 0, 102, 0, 7,
        1, 105, 100, 0, 0, 0, 0, 20, 255, 255, 255, 255, 1, 110, 97, 109, 101, 0, 0, 0, 4, 19,
        255, 255, 255, 255, 1, 97, 103, 101, 0, 0, 0, 0, 23, 255, 255, 255, 255, 1, 101, 109, 97,
        105, 108, 0, 0, 0, 4, 19, 255, 255, 255, 255, 1, 112, 97, 115, 115, 119, 111, 114, 100,
        95, 100, 105, 103, 101, 115, 116, 0, 0, 0, 4, 19, 255, 255, 255, 255, 1, 115, 97, 108, 97,
        114, 121, 0, 0, 0, 6, 164, 0, 6, 0, 6, 1, 115, 101, 120, 0, 0, 0, 0, 16, 255, 255, 255,
        255>>,
    Insert:
      <<73, 0, 0, 89, 103, 78, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 50, 116, 0,
        0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 50, 110, 110, 110, 110>>,
    Delete:
      <<68, 0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52, 56, 116, 0,
        0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 51, 110, 110, 110, 110>>,
    Update:
      <<85, 0, 0, 89, 103, 79, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 53, 50, 116, 0,
        0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 50, 110, 110, 110, 110, 78, 0, 7, 116, 0, 0, 0,
        9, 57, 56, 48, 49, 57, 49, 50, 53, 50, 116, 0, 0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50,
        51, 110, 110, 110, 110>>
  }

  use ExUnit.Case
  alias PostgrexWal.Messages.{Begin, Commit, Delete, Insert, Relation, Update}
  alias PostgrexWal.Messages.Relation.Column

  test "decode begin event" do
    ts = %DateTime{
      calendar: Calendar.ISO,
      day: 16,
      hour: 6,
      microsecond: {719_554, 0},
      minute: 12,
      month: 12,
      second: 34,
      std_offset: 0,
      time_zone: "Etc/UTC",
      utc_offset: 0,
      year: 2022,
      zone_abbr: "UTC"
    }

    assert match?(
             %Begin{
               transaction_id: 3_575,
               commit_timestamp: ^ts,
               final_lsn: {0, 48_495_592}
             },
             PostgrexWal.Message.decode(@binary_events[:Begin])
           )
  end

  test "decode commit event" do
    ts = %DateTime{
      calendar: Calendar.ISO,
      day: 16,
      hour: 6,
      microsecond: {719_554, 0},
      minute: 12,
      month: 12,
      second: 34,
      std_offset: 0,
      time_zone: "Etc/UTC",
      utc_offset: 0,
      year: 2022,
      zone_abbr: "UTC"
    }

    assert match?(
             %Commit{
               commit_timestamp: ^ts,
               end_lsn: {0, 48_495_640},
               lsn: {0, 48_495_592},
               flags: []
             },
             PostgrexWal.Message.decode(@binary_events[:Commit])
           )
  end

  test "decode relation event" do
    columns = [
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
    ]

    assert match?(
             %Relation{
               columns: ^columns,
               number_of_columns: 7,
               replica_identity_setting: [setting: :all_columns],
               relation_name: "users",
               namespace: "public",
               oid: 22_887
             },
             PostgrexWal.Message.decode(@binary_events[:Relation])
           )
  end

  test "decode insert event" do
    data = {{:text, "980191252"}, {:text, "abc"}, {:text, "22"}, nil, nil, nil, nil}

    assert match?(
             %Insert{
               tuple_data: ^data,
               relation_id: 22_887,
               transaction_id: nil
             },
             PostgrexWal.Message.decode(@binary_events[:Insert])
           )
  end

  test "decode delete event" do
    data = {{:text, "980191248"}, {:text, "abc"}, {:text, "23"}, nil, nil, nil, nil}

    assert match?(
             %Delete{
               old_tuple_data: ^data,
               changed_key_tuple_data: nil,
               relation_id: 22_887
             },
             PostgrexWal.Message.decode(@binary_events[:Delete])
           )
  end

  test "decode update event" do
    assert match?(
             %Update{
               old_tuple_data:
                 {{:text, "980191252"}, {:text, "abc"}, {:text, "22"}, nil, nil, nil, nil},
               changed_key_tuple_data: nil,
               tuple_data:
                 {{:text, "980191252"}, {:text, "abc"}, {:text, "23"}, nil, nil, nil, nil},
               relation_id: 22_887
             },
             PostgrexWal.Message.decode(@binary_events[:Update])
           )
  end
end
