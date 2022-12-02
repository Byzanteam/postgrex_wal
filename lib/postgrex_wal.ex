defmodule PostgrexWal do
  use Supervisor

  def start_link(pub_name \\ "postgrex_example", pg_conn_opts) do
    Supervisor.start_link(__MODULE__, {pub_name, pg_conn_opts}, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    children = [
      PostgrexWal.GenStage.Producer,
      PostgrexWal.GenStage.PgSourceRelayer,
      {PostgrexWal.GenStage.PgSource, init_arg}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def child_spec({pub_name, pg_conn_opts}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [pub_name, pg_conn_opts]},
      type: :supervisor
    }
  end
end
