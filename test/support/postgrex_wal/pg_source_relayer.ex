defmodule PostgrexWal.PgSourceRelayer do
  @moduledoc false
  use GenServer
  use TypedStruct
  require Logger

  alias PostgrexWal.{
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
  def handle_info({:message, %Relation{} = _message}, state) do
    {:noreply, state}
  end

  def handle_info({:message, %Commit{} = message}, {receiver, buf}) do
    send(receiver, Enum.reverse([message | buf]))
    {:noreply, {receiver, []}}
  end

  def handle_info({:message, message}, {receiver, buf}) do
    {:noreply, {receiver, [message | buf]}}
  end
end
