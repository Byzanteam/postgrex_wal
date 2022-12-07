defmodule PostgrexWal.Messages do
  @moduledoc false

  alias PostgrexWal.Message.{Begin, Insert, Delete, Relation, Commit, Origin, Update, Truncate, Type}
  def decode(<<key::binary-1, rest::binary>>) do
    modules = %{
      "B" => Begin,
      "C" => Commit,
      "O" => Origin,
      "R" => Relation,
      "I" => Insert,
      "U" => Update,
      "D" => Delete,
      "T" => Truncate,
      "Y" => Type,
    }
    apply(modules[key], :decode, [rest])
  end
end
