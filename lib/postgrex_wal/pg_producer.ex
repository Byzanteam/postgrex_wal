defmodule PostgrexWal.PgProducer do
  use GenStage
  use TypedStruct
  require Logger

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
    field :pg_source, pid(), default: nil
  end

  @impl true
  # opts has been injected with {broadway: Keyword.t()} by Broadway behaviour.
  def init(opts) do
    Logger.info("pg_producer init...")
    send(self(), {:start_pg_source, opts})
    {:producer, %__MODULE__{}}
  end

  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_info({:start_pg_source, opts}, state) do
    {:ok, pid} = PostgrexWal.PgSource.start_link(opts ++ [subscriber: self()])
    {:noreply, [], %{state | pg_source: pid}}
  end

  @doc """
  Broadway.NoopAcknowledger.init() produce: {Broadway.NoopAcknowledger, nil, nil}
  Broadway.CallerAcknowledger.init({pid, ref}, term) produce: {Broadway.CallerAcknowledger, {#PID<0.275.0>, ref}, term}
  """
  def handle_info({:events, events}, state) do
    noop_acker = Broadway.NoopAcknowledger.init()
    op_acker = {__MODULE__, state.pg_source, :ack_data}

    events =
      for event <- events do
        message = PostgrexWal.Message.decode(event)

        acker =
          if is_struct(message, PostgrexWal.Messages.Commit),
            do: op_acker,
            else: noop_acker

        %Broadway.Message{
          data: message,
          acknowledger: acker
        }
      end

    {:noreply, events, state}
  end

  @behaviour Broadway.Acknowledger
  @impl true
  def ack(pg_source, successful, _failed) do
    lsn =
      successful
      |> Enum.reverse()
      |> Enum.find_value(fn m ->
        is_struct(m.data, PostgrexWal.Messages.Commit) && m.data.end_lsn
      end)

    lsn && PostgrexWal.PgSource.ack(pg_source, lsn)
  end
end
