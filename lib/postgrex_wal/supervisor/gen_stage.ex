defmodule Postgrex.Supervisor.GenStage do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      PostgrexWal.GenStage.Producer,
      PostgrexWal.GenStage.MockedConsumer
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
