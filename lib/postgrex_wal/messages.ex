defmodule PostgrexWal.Messages do
  @moduledoc false

  alias PostgrexWal.Message.{Begin, Commit, Relation, Insert, Delete, Truncate, Type, Update, Origin}
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
    apply(modules[key], :decode, [rest])
  end
end
