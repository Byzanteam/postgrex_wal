defmodule PostgrexWal.Messages.Stop do
  @moduledoc """
  Byte1('E')
  Identifies the message as a stream stop message.
  """
  use PostgrexWal.Message

  typedstruct enforce: true do
    field :flag, String.t()
  end

  @impl true
  def decode(<<>>) do
    %__MODULE__{flag: "stop"}
  end
end
