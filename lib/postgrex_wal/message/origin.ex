defmodule PostgrexWal.Message.Origin do
  @moduledoc """
  A Origin message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :origin_commit_lsn, Integer
    field :name, String.t
  end

  def decode(<<lsn::8, name::binary>>) do
    %__MODULE__{
      origin_commit_lsn: lsn,
      name: name
    }
  end
end
