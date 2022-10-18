defmodule PostgrexWal.Messages do
  @moduledoc false

  @message_mods [
    PostgrexWal.Message.BeginMessage,
    PostgrexWal.Message.InsertMessage,
    PostgrexWal.Message.DeleteMessage,
    PostgrexWal.Message.RelationMessage,
    PostgrexWal.Message.CommitMessage
  ]

  clauses =
    Enum.flat_map(@message_mods, fn mod ->
      mod.decode(true)
    end)

  decoding_ast =
    quote location: :keep do
      def decode(msg) do
        case msg, do: unquote(clauses)
      end
    end

  Module.eval_quoted(__MODULE__, decoding_ast)
end
