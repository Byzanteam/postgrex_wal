ExUnit.start(timeout: 5_000)

pg_conn_opts = [
  host: "localhost",
  database: "r704_development",
  username: "jswk"
]

producer_name = :my_prod
PostgrexWal.start_link(producer_name: producer_name, publication_name: "postgrex_example", pg_conn_opts: pg_conn_opts)
Support.MockedConsumer.start_link(producer_name)
{:ok, pg_pid} = Postgrex.start_link(pg_conn_opts)
Process.register(pg_pid, PgConn)
