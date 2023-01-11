defmodule PostgrexWal.Producer do
  @moduledoc false
  @behaviour Broadway.Producer

  use GenStage
  use TypedStruct
  require Logger

  # other callbacks...

  typedstruct enforce: true do
    field :pg_source_name, GenServer.name()
    field :queue, :queue.queue(struct), default: :queue.new()
    field :pending_demand, integer(), default: 0
  end

  ## Client API

  @impl true
  def prepare_for_start(_module, broadway_options) do
    children = [
      {PostgrexWal.PgSource, broadway_options}
    ]

    {children, broadway_options}
  end

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

          acknowledger =
            if is_struct(m, PostgrexWal.Messages.Commit),
              do: {__MODULE__, {state.pg_source_name, get_lsn(m)}, :ack_data},
              else: Broadway.NoopAcknowledger.init()

          %Broadway.Message{
            data: m,
            acknowledger: acknowledger
          }
          |> :queue.in(acc)
      end

    dispatch_events(%{state | queue: queue}, [])
  end

  def ack({pg_source_name, lsn}, _succ, _fail) do
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

  defp get_lsn(%{end_lsn: lsn}), do: lsn
end
