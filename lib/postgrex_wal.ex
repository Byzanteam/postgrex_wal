defmodule PostgrexWal do
  use Supervisor

  def start_link(pg_conn_opts) do
    Supervisor.start_link(__MODULE__, pg_conn_opts, name: __MODULE__)
  end

  @impl true
  def init(pg_conn_opts) do
    children = [
      PostgrexWal.GenStage.Producer,
      PostgrexWal.GenStage.PgSourceRelayer,
      {PostgrexWal.GenStage.PgSource, pg_conn_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one) #strategy, max_restarts, max_seconds.
  end
end
