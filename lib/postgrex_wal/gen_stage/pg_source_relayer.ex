defmodule PostgrexWal.GenStage.PgSourceRelayer do
  use GenServer
  require Logger

  def start_link(producer_name) do
    GenServer.start_link(__MODULE__, {[], producer_name}, name: __MODULE__)
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
  def handle_cast({:async_event, event}, {list, producer_name}) do
    event = PgoutputDecoder.decode_message(event) |> IO.inspect

    if is_a?(event, "Begin") and length(list) > 0 do
      Logger.info "residual events exists"
    end

    list = [event | list]
    case event |> is_a?("Commit") do
      true ->
        Enum.reverse(list) |> PostgrexWal.GenStage.Producer.sync_notify(producer_name)
        {:noreply, {[], producer_name}}
      false ->
        {:noreply, {list, producer_name}}
    end
  end

  defp is_a?(event, str) do
    event
    |> Map.get(:__struct__)
    |> Atom.to_string
    |> String.ends_with?(str)
  end
end
