defmodule PostgrexWal.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    IO.puts "--- start #{__MODULE__} ---"
    children = [
      PostgrexWal.Registry,
      PostgrexWal.DynamicSupervisor,
      Postgrex.Supervisor.GenStage,
      PostgrexWal.GenStage.PgSourceRelayer,
      {PostgrexWal.GenStage.PgSource, Application.fetch_env!(:postgrex_wal, :db_conn_info)}
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Supervisor.start_link(children, opts)
  end

  # before the supervision tree is terminated.
  @impl true
  def prep_stop(state) do
    # cleanup code
    state
  end

  # called after the supervision tree has been stopped by the runtime.
  @impl true
  def stop(_new_state) do
    # cleanup code
    :ok
  end
end
