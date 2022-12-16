defmodule PostgrexWal.Message.Origin do
  @moduledoc """
  A Origin message
  """

  use PostgrexWal.Message

  typedstruct enforce: true do
    field :origin_commit_lsn, Helper.lsn()
    field :name, String.t()
  end

  @impl true
  def decode(<<lsn::binary-8, name::binary>>) do
    %__MODULE__{
      origin_commit_lsn: Helper.decode_lsn(lsn),
      name: name
    }
  end
end
