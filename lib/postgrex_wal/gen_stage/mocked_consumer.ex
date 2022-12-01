defmodule PostgrexWal.GenStage.MockedConsumer do
  use GenStage

  ## Client API

  def start_link(_) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def events_fetch() do
    GenStage.call(__MODULE__, :fetch_state)
  end

  ## Server Callback

  @impl true
  def init(state) do
    {:consumer, state, subscribe_to: [PostgrexWal.GenStage.Producer]}
  end

  @impl true
  def handle_call(:fetch_state, from, state) do
    GenStage.reply(from, state)
    {:noreply, [], []}
  end

  @impl true
  def handle_events(events, _from, state) do
    {:noreply, [], events ++ state}
  end
end
