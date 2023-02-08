defmodule PostgrexWal.PgProducer do
  use GenStage
  use TypedStruct
  require Logger

  alias PostgrexWal.{Messages.Commit, PgSource}

  @moduledoc """
  A PostgreSQL wal events producer for Broadway.

  ## Features

    * Automatically acknowledges messages.
    * Handles connection automatically.

  ## Example

      defmodule MyBroadway do
        use Broadway

        def start_link(_opts) do
          Broadway.start_link(__MODULE__,
            name: __MODULE__,
            producer: [
              module: {
                PostgrexWal.PgProducer,
                name: :my_pg_source,
                publication_name: "my_pub",
                slot_name: "my_slot",
                username: "postgres",
                database: "postgres",
                password: "postgres",
                host: "localhost",
                port: "5432"
              }
            ],
            processors: [
              default: [max_demand: 1]
            ]
          )
        end

        @impl true
        def handle_message(_processor_name, message, _context) do
          message |> IO.inspect()
        end
      end
  """

  typedstruct do
    @typedoc "Producer's state"
    field :pg_source, pid()
    field :queue, :queue.queue(), default: :queue.new()
    field :pending_demand, non_neg_integer(), default: 0
    field :max_size, non_neg_integer(), default: 10_000
    field :current_size, non_neg_integer(), default: 0
    field :overflowed?, boolean(), default: false
  end

  @impl true
  # opts has been injected with {broadway: Keyword.t()} by Broadway behaviour.
  def init(opts) do
    Logger.debug("pg_producer init...")
    {init_opts, opts} = Keyword.split(opts, [:max_size])
    send(self(), {:start_pg_source, opts})
    {:producer, struct!(__MODULE__, init_opts)}
  end

  @impl true
  def handle_info({:start_pg_source, opts}, state) do
    {:ok, pid} = PgSource.start_link(opts ++ [subscriber: self()])
    {:noreply, [], %{state | pg_source: pid}}
  end

  def handle_info(:overflowed_exit = reason, state) do
    Logger.info("PgProducer restart due to overflowed!")
    {:stop, reason, state}
  end

  @doc """
  Broadway.NoopAcknowledger.init() produce: {Broadway.NoopAcknowledger, nil, nil}
  Broadway.CallerAcknowledger.init({pid, ref}, term) produce: {Broadway.CallerAcknowledger, {#PID<0.275.0>, ref}, term}
  """

  def handle_info({:message, _}, %{overflowed?: true} = state) do
    {:noreply, [], state}
  end

  def handle_info({:message, _}, %{current_size: max, max_size: max} = state) do
    {:noreply, [], %{state | overflowed?: true}}
  end

  def handle_info({:message, message}, %{current_size: s} = state) do
    acker =
      if is_struct(message, Commit),
        do: {__MODULE__, {:pg_source, state.pg_source}, :ack_data},
        else: Broadway.NoopAcknowledger.init()

    event = %Broadway.Message{
      data: message,
      acknowledger: acker
    }

    %{state | queue: :queue.in(event, state.queue), current_size: s + 1}
    |> dispatch_events()
  end

  @impl true
  def handle_demand(incoming_demand, %{pending_demand: p} = state) do
    %{state | pending_demand: incoming_demand + p}
    |> dispatch_events()
  end

  @doc """
  If there are no batchers, the acknowledgement will be done by processors.
  The number of messages acknowledged, assuming the pipeline is running at full scale,
  will be max_demand - min_demand.
  Since the default values are 10 and 5 respectively, we will be acknowledging in groups of 5.
  """

  @behaviour Broadway.Acknowledger
  @impl true
  def ack({:pg_source, pg_source}, successful_messages, _failed_messages) do
    lsn =
      successful_messages
      |> Enum.reverse()
      |> Enum.find_value(fn m ->
        is_struct(m.data, Commit) && m.data.end_lsn
      end)

    lsn && PgSource.ack(pg_source, lsn)
  end

  defp dispatch_events(state, events \\ [])

  defp dispatch_events(%{pending_demand: 0} = state, events) do
    {:noreply, Enum.reverse(events), state}
  end

  defp dispatch_events(%{pending_demand: p, current_size: s} = state, events) do
    case :queue.out(state.queue) do
      {{:value, event}, queue} ->
        %{state | pending_demand: p - 1, current_size: s - 1, queue: queue}
        |> dispatch_events([event | events])

      {:empty, _queue} ->
        if state.overflowed?, do: send(self(), :overflowed_exit)
        {:noreply, Enum.reverse(events), state}
    end
  end
end
