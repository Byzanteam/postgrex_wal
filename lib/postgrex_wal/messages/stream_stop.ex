defmodule PostgrexWal.Messages.StreamStop do
  @moduledoc """
  Byte1('E')
  Identifies the message as a stream stop message.
  """
  use PostgrexWal.GenMessage

  typedstruct do
  end

  @impl true
  def decode(<<>>) do
    %__MODULE__{}
  end

  def identifier, do: ?E
end
