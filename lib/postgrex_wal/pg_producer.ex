defmodule PostgrexWal.PgProducer do
  use GenStage

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

  @impl true
  def init(opts) do
    PostgrexWal.PgSource.subscribe(opts[:name])
    {:producer, pg_source: opts[:name]}
  end

  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  @impl true
  def handle_info({:events, events}, state) do
    events =
      for event <- events do
        %Broadway.Message{
          data: PostgrexWal.Message.decode(event),
          acknowledger: {__MODULE__, state[:pg_source], :ack_data}
        }
      end

    {:noreply, events, state}
  end

  @impl Broadway.Producer
  def prepare_for_start(_module, broadway_opts) do
    {_producer_module, opts} = broadway_opts[:producer][:module]

    children = [
      {PostgrexWal.PgSource, opts}
    ]

    {children, broadway_opts}
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
