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
  def handle_call({:message, %Relation{} = _message}, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:message, %Commit{} = message}, _from, {receiver, buf}) do
    send(receiver, Enum.reverse([message | buf]))
    {:reply, :ok, {receiver, []}}
  end

  def handle_call({:message, message}, _from, {receiver, buf}) do
    {:reply, :ok, {receiver, [message | buf]}}
  end
end
