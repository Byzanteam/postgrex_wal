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

  def handle_info({:events, events}, state) do
    events =
      for event <- events do
        %Broadway.Message{
          data: PostgrexWal.Message.decode(event),
          acknowledger: {__MODULE__, state.pg_source, :ack_data}
        }
      end

    {:noreply, events, state}
  end

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
