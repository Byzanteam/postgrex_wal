defmodule PostgrexWal.Messages.StreamStop do
  @moduledoc """
  Byte1('E')
  Identifies the message as a stream stop message.
  """
  use PostgrexWal.Message

  typedstruct do
  end

  @impl true
  def decode(<<>>) do
    %__MODULE__{}
  end
end
