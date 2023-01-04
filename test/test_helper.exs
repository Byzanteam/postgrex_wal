ExUnit.start(assert_receive_timeout: 2_000, seed: 0)

sql_test = """
CREATE TABLE IF NOT EXISTS users (a int, b text);
SELECT pg_create_logical_replication_slot('myslot5', 'pgoutput');
CREATE PUBLICATION mypub5 FOR all tables;
ALTER TABLE users REPLICA IDENTITY FULL;
"""

PostgrexWal.PSQL.cmd(sql_test)
