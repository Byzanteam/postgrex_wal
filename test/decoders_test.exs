defmodule DecodersTest do
  @binary_events %{
    Begin: <<0, 0, 0, 0, 2, 227, 88, 24, 0, 2, 146, 73, 163, 88, 236, 129, 0, 0, 13, 229>>,
    Commit:
      <<0, 0, 0, 0, 0, 2, 227, 88, 24, 0, 0, 0, 0, 2, 227, 88, 72, 0, 2, 146, 73, 163, 88, 236,
        129>>,
    Relation:
      <<0, 0, 89, 103, 112, 117, 98, 108, 105, 99, 0, 117, 115, 101, 114, 115, 0, 100, 0, 7, 1,
        105, 100, 0, 0, 0, 0, 20, 255, 255, 255, 255, 0, 110, 97, 109, 101, 0, 0, 0, 4, 19, 255,
        255, 255, 255, 0, 97, 103, 101, 0, 0, 0, 0, 23, 255, 255, 255, 255, 0, 101, 109, 97, 105,
        108, 0, 0, 0, 4, 19, 255, 255, 255, 255, 0, 112, 97, 115, 115, 119, 111, 114, 100, 95,
        100, 105, 103, 101, 115, 116, 0, 0, 0, 4, 19, 255, 255, 255, 255, 0, 115, 97, 108, 97,
        114, 121, 0, 0, 0, 6, 164, 0, 6, 0, 6, 0, 115, 101, 120, 0, 0, 0, 0, 16, 255, 255, 255,
        255>>,
    Insert:
      <<0, 0, 89, 103, 78, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52, 51, 116, 0, 0,
        0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 50, 110, 110, 110, 110>>,
    Delete:
      <<0, 0, 89, 103, 75, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52, 49, 110, 110,
        110, 110, 110, 110>>,
    Update:
      <<0, 0, 89, 103, 78, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52, 52, 116, 0, 0,
        0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 51, 110, 110, 110, 110>>
  }

  use ExUnit.Case
  alias PostgrexWal.Message.{Begin, Commit, Delete, Insert, Relation, Update}

  test "decode begin event" do
    assert match?(
             %Begin{
               final_lsn: 48_453_656,
               commit_timestamp: 723_794_924_203_137,
               xid: 3_557
             },
             Begin.decode(@binary_events[:Begin])
           )
  end

  test "decode commit event" do
    assert match?(
             %Commit{
               commit_timestamp: 723_794_924_203_137,
               end_lsn: 48_453_704,
               lsn: 48_453_656
             },
             Commit.decode(@binary_events[:Commit])
           )
  end

  test "decode relation event" do
    assert match?(
             %Relation{
               data: a,
               number_of_columns: 7,
               replica_identity_setting: 100,
               relation_name: "users",
               namespace: "public",
               id: 22_887
             }
             when is_list(a) and length(a) == 7,
             Relation.decode(@binary_events[:Relation])
           )
  end

  test "decode insert event" do
    assert match?(
             %Insert{
               data: a,
               oid: 22_887,
               transaction_id: b
             }
             when is_list(a) and length(a) == 7 and is_nil(b),
             Insert.decode(@binary_events[:Insert])
           )
  end

  test "decode delete event" do
    assert match?(
             %Delete{
               data: a,
               relation_id: 22_887
             }
             when is_list(a) and length(a) == 7,
             Delete.decode(@binary_events[:Delete])
           )
  end

  test "decode update event" do
    assert match?(
             %Update{
               relation_id: 22_887,
               tuple_data: a
             }
             when is_list(a) and length(a) == 7,
             Update.decode(@binary_events[:Update])
           )
  end
end
