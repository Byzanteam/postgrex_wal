defmodule PostgrexWal.Messages.Stop do
  @moduledoc """
  Byte1('E')
  Identifies the message as a stream stop message.
  """
  use PostgrexWal.Message

  typedstruct do
    field :message_flag, String.t(), default: "stop"
  end

  @impl true
  def decode(<<>>) do
    %__MODULE__{}
  end
end
