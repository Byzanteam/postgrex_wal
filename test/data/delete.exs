# pg_query("DELETE FROM users WHERE name = 'abc'")
event1 =
  <<66, 0, 0, 0, 0, 2, 227, 88, 24, 0, 2, 146, 73, 163, 88, 236, 129, 0, 0, 13, 229>>

%PgoutputDecoder.Messages.Begin{
  final_lsn: {0, 48453656},
  commit_timestamp: ~U[2022-12-08 06:08:44Z],
  xid: 3557
}
%PostgrexWal.Message.Begin{
  xid: 3557,
  commit_timestamp: 723794924203137,
  final_lsn: 48453656
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

event3 = <<68, 0, 0, 89, 103, 75, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52,
49, 110, 110, 110, 110, 110, 110>>

%PgoutputDecoder.Messages.Delete{
  relation_id: 22887,
  changed_key_tuple_data: {"980191241", nil, nil, nil, nil, nil, nil},
  old_tuple_data: nil
}
%PostgrexWal.Message.Delete{
  data: [{:text, "980191241"}, nil, nil, nil, nil, nil, nil],
  relation_id: 22887
}


event4 = <<68, 0, 0, 89, 103, 75, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52,
50, 110, 110, 110, 110, 110, 110>>
%PgoutputDecoder.Messages.Delete{
  relation_id: 22887,
  changed_key_tuple_data: {"980191242", nil, nil, nil, nil, nil, nil},
  old_tuple_data: nil
}
%PostgrexWal.Message.Delete{
  data: [{:text, "980191242"}, nil, nil, nil, nil, nil, nil],
  relation_id: 22887
}

event5 =
  <<68, 0, 0, 89, 103, 75, 0, 7, 116, 0, 0, 0, 9, 57, 56, 48, 49, 57, 49, 50, 52,
51, 110, 110, 110, 110, 110, 110>>
%PgoutputDecoder.Messages.Delete{
  relation_id: 22887,
  changed_key_tuple_data: {"980191243", nil, nil, nil, nil, nil, nil},
  old_tuple_data: nil
}
%PostgrexWal.Message.Delete{
  data: [{:text, "980191243"}, nil, nil, nil, nil, nil, nil],
  relation_id: 22887
}

event6 =
  <<67, 0, 0, 0, 0, 0, 2, 227, 88, 24, 0, 0, 0, 0, 2, 227, 88, 72, 0, 2, 146, 73,
163, 88, 236, 129>>
%PgoutputDecoder.Messages.Commit{
  flags: [],
  lsn: {0, 48453656},
  end_lsn: {0, 48453704},
  commit_timestamp: ~U[2022-12-08 06:08:44Z]
}

%PostgrexWal.Message.Commit{
  commit_timestamp: 723794924203137,
  end_lsn: 48453704,
  lsn: 48453656
}
