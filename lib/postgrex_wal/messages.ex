defmodule PostgrexWal.Messages do
  @moduledoc false

  alias PostgrexWal.Message.{
    Begin,
    Commit,
    Delete,
    Insert,
    Origin,
    Relation,
    Truncate,
    Type,
    Update
  }

  def decode(<<key::binary-1, rest::binary>>) do
    modules = %{
      "B" => Begin,
      "C" => Commit,
      "R" => Relation,
      "I" => Insert,
      "D" => Delete,
      "T" => Truncate,
      "Y" => Type,
      "U" => Update,
      "O" => Origin
    }

    modules[key].decode(rest)
  end
end
