defmodule PostgrexWal.GenStage.PgSourceRelayer do
  use GenServer

  # Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def async_notify(event) do
    GenServer.cast(__MODULE__, {:async_event, event})
  end

  # Server (callbacks)

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:async_event, event}, state) do
    event
      |> PgoutputDecoder.decode_message
      |> PostgrexWal.GenStage.Producer.sync_notify
    {:noreply, state}
  end
end
