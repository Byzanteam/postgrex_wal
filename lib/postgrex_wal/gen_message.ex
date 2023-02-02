defmodule PostgrexWal.GenMessage do
  @moduledoc false

  @callback decode(message :: binary()) :: struct()
  @callback identifier() :: byte()
  @type tuple_data() :: nil | :unchanged_toast | {:text, binary()} | {:binary, bitstring()}

  defmacro __using__(_opts) do
    quote do
      @behaviour PostgrexWal.GenMessage
      use TypedStruct
      alias PostgrexWal.GenMessage
      alias PostgrexWal.Messages.Util
    end
  end
end
