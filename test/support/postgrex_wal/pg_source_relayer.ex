defmodule PostgrexWal.PgSourceRelayer do
  @moduledoc false
  use GenServer
  use TypedStruct
  require Logger

  typedstruct do
    field :receiver, pid()
    field :buf, list(), default: []
  end

  @doc """
  opts = [
   pg_source: PostgrexWal.PgSource,
   receiver: Tester,
  ]
  """
  @spec start_link(opts :: {GenServer.server(), pid()}) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # Callbacks

  @impl true
  def init({pg_source, receiver}) do
    PostgrexWal.PgSource.subscribe(pg_source)
    {:ok, %__MODULE__{receiver: receiver}}
  end

  @impl true
  def handle_info({:events, events}, state) do
    buf = do_decode(events, state.receiver, state.buf)
    {:noreply, %{state | buf: buf}}
  end

  def do_decode([], _receiver, buf), do: buf

  def do_decode([event | rest], receiver, buf) do
    msg = PostgrexWal.Message.decode(event)

    if is_struct(msg, PostgrexWal.Messages.Relation) do
      do_decode(rest, receiver, buf)
    else
      buf = [msg | buf]

      buf =
        if is_struct(msg, PostgrexWal.Messages.Commit) do
          send(receiver, Enum.reverse(buf))
          []
        else
          buf
        end

      do_decode(rest, receiver, buf)
    end
  end
end
