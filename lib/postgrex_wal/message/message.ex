defmodule PostgrexWal.Message do
  @moduledoc """
  Logical Replication Message Formats.

  https://www.postgresql.org/docs/15/protocol-logicalrep-message-formats.html
  """

  @type state() :: term()

  @callback decode(state) :: Macro.t()

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour PostgrexWal.Message

      use TypedStruct
    end
  end
end
