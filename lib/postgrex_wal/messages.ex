defmodule PostgrexWal.Messages do
  @moduledoc false

  alias PostgrexWal.Message.{Begin, Commit, Relation, Insert, Delete}
  def decode(<<key::binary-1, rest::binary>>) do
    modules = %{
      "B" => Begin,
      "C" => Commit,
      "R" => Relation,
      "I" => Insert,
      "D" => Delete
    }
    apply(modules[key], :decode, [rest])
  end
end
