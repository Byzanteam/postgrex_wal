defmodule Support.MockedConsumer do
  use GenStage

  ## Client API

  def start_link(producer_name) do
    GenStage.start_link(__MODULE__, producer_name, name: __MODULE__)
  end

  ## Server Callback

  @impl true
  def init(producer_name) do
    {:consumer, producer_name, subscribe_to: [producer_name]}
  end

  @impl true
  def handle_events([events], _from, state) do
    send Tester, {:consumer_events, events}
    {:noreply, [], state}
  end
end
