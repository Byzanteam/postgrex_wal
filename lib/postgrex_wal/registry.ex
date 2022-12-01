defmodule PostgrexWal.Registry do
  @moduledoc false

  def start_link(opts) do
    extra = [keys: :unique, name: __MODULE__, ]
    Registry.start_link(opts ++ extra)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  def lookup!(key) do
    [{_pid, _value} = result] = Registry.lookup(__MODULE__, key)
    result
  end

  def register!(key, value \\[]) do
    {:ok, _} = Registry.register(__MODULE__, key, value)
  end

  def child_spec(opts) when is_list(opts) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    )
  end
end
