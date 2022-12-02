defmodule PostgrexWal.GenStage.PgSourceRelayer do
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
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
    event = PgoutputDecoder.decode_message(event)

    if is_a?(event, "Begin") and length(state) > 0 do
      Logger.info "residual events exists"
    end

    state = [event | state]
    case event |> is_a?("Commit") do
      true ->
        Enum.reverse(state) |> PostgrexWal.GenStage.Producer.sync_notify
        {:noreply, []}
      false ->
        {:noreply, state}
    end
  end

  defp is_a?(event, str) do
    event
    |> Map.get(:__struct__)
    |> Atom.to_string
    |> String.ends_with?(str)
  end
end
