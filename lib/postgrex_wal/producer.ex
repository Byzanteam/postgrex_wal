defmodule PostgrexWal.Producer do
  @moduledoc false

  use GenStage
  use TypedStruct
  require Logger

  typedstruct enforce: true do
    field :pg_source_name, GenServer.name()
    field :queue, :queue.queue(struct), default: :queue.new()
    field :pending_demand, integer(), default: 0
  end

  ## Client API

  def start_link(producer_name \\ __MODULE__) do
    GenStage.start_link(__MODULE__, nil, name: producer_name)
  end

  ## Server Callbacks

  @impl true
  def init(opts) do
    # {:ok, _pid} = PostgrexWal.PgSource.start_link(opts ++ [subscriber: self()])
    {:producer, %__MODULE__{pg_source_name: opts[:name]}}
  end

  @impl true
  def handle_info({:events, events}, state) do
    queue =
      for e <- events, reduce: state.queue do
        acc ->
          m = PostgrexWal.Message.decode(e)

          %Broadway.Message{
            data: m,
            acknowledger: {__MODULE__, {state.pg_source_name, get_lsn(m)}, :ack_data}
          }
          |> :queue.in(acc)
      end

    dispatch_events(%{state | queue: queue}, [])
  end

  def ack({_pg_source_name, ""}, _, _), do: :ok

  def ack({pg_source_name, lsn}, _successful, _failed) do
    PostgrexWal.PgSource.ack(pg_source_name, lsn)
    :ok
  end

  @impl true
  def handle_demand(incoming_demand, state) when incoming_demand > 0 do
    dispatch_events(%{state | pending_demand: incoming_demand + state.pending_demand}, [])
  end

  defp dispatch_events(%{pending_demand: 0} = state, events) do
    {:noreply, Enum.reverse(events), state}
  end

  defp dispatch_events(state, events) do
    case :queue.out(state.queue) do
      {{:value, e}, queue} ->
        dispatch_events(
          %{state | queue: queue, pending_demand: state.pending_demand - 1},
          [e | events]
        )

      {:empty, _queue} ->
        {:noreply, Enum.reverse(events), state}
    end
  end

  defp get_lsn(%PostgrexWal.Messages.Commit{end_lsn: lsn}), do: lsn
  defp get_lsn(_), do: ""
end
