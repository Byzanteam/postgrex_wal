defmodule PostgrexWal.Message do
  @moduledoc false

  @callback decode(message :: binary()) :: struct()

  defmacro __using__(_opts) do
    quote do
      @behaviour PostgrexWal.Message
      use TypedStruct
      alias PostgrexWal.Message.Helper
    end
  end

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

  @modules %{
    ?B => Begin,
    ?C => Commit,
    ?D => Delete,
    ?I => Insert,
    ?O => Origin,
    ?R => Relation,
    ?T => Truncate,
    ?Y => Type,
    ?U => Update
  }

  for {key, module} <- @modules do
    def decode(<<unquote(key)::8, payload::binary>>) do
      unquote(module).decode(payload)
    end
  end
end
