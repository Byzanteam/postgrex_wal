ExUnit.start()

defmodule MockedConsumer do
  use GenStage

  ## Client API

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  ## Server Callback

  @impl true
  def init(state) do
    {:consumer, state, subscribe_to: [PostgrexWal.GenStage.Producer]}
  end

  @impl true
  def handle_events(events, _from, state) do
    send Tester, List.flatten(events)
    {:noreply, [], state}
  end
end

opts = [
  host: "localhost",
  database: "r704_development",
  username: "jswk"
]

PostgrexWal.start_link(opts)
MockedConsumer.start_link()
{:ok, pg_pid} = Postgrex.start_link(opts)
Process.register(pg_pid, PgConn)
