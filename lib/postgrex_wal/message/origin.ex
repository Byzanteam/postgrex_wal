defmodule PostgrexWal.Message.Origin do
  @moduledoc """
  A commit message
  """

  use TypedStruct

  typedstruct enforce: true do
    field :origin_commit_lsn, integer()
    field :name, string()
  end

  def decode(<<lsn::8, name::binary>>) do
    %__MODULE__{
      origin_commit_lsn: lsn,
      name: name
    }
  end
end
