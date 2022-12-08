# pg_query("DELETE FROM users WHERE name = 'abc'")
event1 =
  <<66, 0, 0, 0, 0, 2, 227, 105, 168, 0, 2, 146, 73, 215, 42, 157, 86, 0, 0, 13, 231>>
%PgoutputDecoder.Messages.Begin{
  final_lsn: {0, 48458152},
  commit_timestamp: ~U[2022-12-08 06:23:13Z],
  xid: 3559
}
%PostgrexWal.Message.Begin{
  xid: 3559,
  commit_timestamp: 723795793583446,
  final_lsn: 48458152
}


event2 =
  <<82, 0, 0, 89, 103, 112, 117, 98, 108, 105, 99, 0, 117, 115, 101, 114, 115, 0,
100, 0, 7, 1, 105, 100, 0, 0, 0, 0, 20, 255, 255, 255, 255, 0, 110, 97, 109,
101, 0, 0, 0, 4, 19, 255, 255, 255, 255, 0, 97, 103, 101, 0, 0, 0, 0, 23, 255,
255, 255, 255, 0, 101, 109, 97, 105, 108, 0, 0, 0, 4, 19, 255, 255, 255, 255,
0, 112, 97, 115, 115, 119, 111, 114, 100, 95, 100, 105, 103, 101, 115, 116, 0,
0, 0, 4, 19, 255, 255, 255, 255, 0, 115, 97, 108, 97, 114, 121, 0, 0, 0, 6,
164, 0, 6, 0, 6, 0, 115, 101, 120, 0, 0, 0, 0, 16, 255, 255, 255, 255>>
%PgoutputDecoder.Messages.Relation{
  id: 22887,
  namespace: "public",
  name: "users",
  replica_identity: :default,
  columns: [
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [:key],
      name: "id",
      type: :int8,
      type_modifier: 4294967295
    },
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [],
      name: "name",
      type: :varchar,
      type_modifier: 4294967295
    },
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [],
      name: "age",
      type: :int4,
      type_modifier: 4294967295
    },
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [],
      name: "email",
      type: :varchar,
      type_modifier: 4294967295
    },
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [],
      name: "password_digest",
      type: :varchar,
      type_modifier: 4294967295
    },
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [],
      name: "salary",
      type: :unknown,
      type_modifier: 393222
    },
    %PgoutputDecoder.Messages.Relation.Column{
      flags: [],
      name: "sex",
      type: :bool,
      type_modifier: 4294967295
    }
  ]
}
%PostgrexWal.Message.Relation{
  data: [
    %{column_name: "id", flags: 1, type_modifier: 4294967295, type_oid: 20},
    %{column_name: "name", flags: 0, type_modifier: 4294967295, type_oid: 1043},
    %{column_name: "age", flags: 0, type_modifier: 4294967295, type_oid: 23},
    %{column_name: "email", flags: 0, type_modifier: 4294967295, type_oid: 1043},
    %{
      column_name: "password_digest",
      flags: 0,
      type_modifier: 4294967295,
      type_oid: 1043
    },
    %{column_name: "salary", flags: 0, type_modifier: 393222, type_oid: 1700},
    %{column_name: "sex", flags: 0, type_modifier: 4294967295, type_oid: 16}
  ],
  number_of_columns: 7,
  replica_identity_setting: 100,
  relation_name: "users",
  namespace: "public",
  id: 22887
}

event3 =
  <<85, 0, 0, 89, 103, 78, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52,
52, 116, 0, 0, 0, 3, 97, 98, 99, 116, 0, 0, 0, 2, 50, 51, 110, 110, 110, 110>>
%PgoutputDecoder.Messages.Update{
  relation_id: 22887,
  changed_key_tuple_data: nil,
  old_tuple_data: nil,
  tuple_data: {"980191244", "abc", "23", nil, nil, nil, nil}
}
%PostgrexWal.Message.Update{
  relation_id: 22887,
  tuple_data: [
    {:text, "980191244"},
    {:text, "abc"},
    {:text, "23"},
    nil,
    nil,
    nil,
    nil
  ]
}

event4 =
  <<67, 0, 0, 0, 0, 0, 2, 227, 105, 168, 0, 0, 0, 0, 2, 227, 105, 216, 0, 2, 146,
73, 215, 42, 157, 86>>
%PgoutputDecoder.Messages.Commit{
  flags: [],
  lsn: {0, 48458152},
  end_lsn: {0, 48458200},
  commit_timestamp: ~U[2022-12-08 06:23:13Z]
}
%PostgrexWal.Message.Commit{
  commit_timestamp: 723795793583446,
  end_lsn: 48458200,
  lsn: 48458152
}
