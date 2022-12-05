defmodule PostgrexWal do
  use Supervisor

  # opts: [register_name: atom(), publication_name: atom(), pg_conn_opts: keyword()]
  def start_link(opts) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    producer_name = Keyword.fetch!(opts, :producer_name)
    pg_source_opts = [
      pg_conn_opts: Keyword.fetch!(opts, :pg_conn_opts),
      publication_name: Keyword.fetch!(opts, :publication_name)
    ]

    children = [
      {PostgrexWal.GenStage.Producer, producer_name},
      {PostgrexWal.GenStage.PgSourceRelayer, producer_name},
      {PostgrexWal.GenStage.PgSource, pg_source_opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
