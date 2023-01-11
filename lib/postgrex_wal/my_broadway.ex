defmodule MyBroadway do
  @moduledoc false
  use Broadway
  require Logger

  @doc """
  ## Example
  	opts = [
  		name: PostgrexWal.PgSource,
  		publication_name: "my_pub",
  		slot_name: "my_slot",
  		database: "postgres",
  		username: "postgres"
  	]

  		MyBroadway.start_link(opts)
  """

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {PostgrexWal.Producer, opts},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ]
    )
  end

  def handle_message(_, message, _) do
    message
  end
end
