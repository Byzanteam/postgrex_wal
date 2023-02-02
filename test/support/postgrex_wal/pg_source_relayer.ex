defmodule PostgrexWal.PgSourceRelayer do
  @moduledoc false
  use GenServer
  use TypedStruct
  require Logger

  alias PostgrexWal.{
    Message,
    Messages.Commit,
    Messages.Relation,
    PgSource
  }

  @typep opts() :: {GenServer.server(), pid()}
  @spec start_link(opts()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init({receiver, opts}) do
    {:ok, {receiver, []}, {:continue, {:start_pg_source, opts}}}
  end

  @impl true
  def handle_continue({:start_pg_source, opts}, state) do
    PgSource.start_link(opts ++ [subscriber: self()])
    {:noreply, state}
  end

  @impl true
  def handle_info({:events, events}, {receiver, buf}) do
    buf =
      for e <- events,
          m = Message.decode(e),
          !is_struct(m, Relation),
          reduce: buf do
        acc ->
          acc = [m | acc]

          if is_struct(m, Commit) do
            send(receiver, Enum.reverse(acc))
            []
          else
            acc
          end
      end

    {:noreply, {receiver, buf}}
  end
end
