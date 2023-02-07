defmodule PostgrexWal do
  @moduledoc false

  defmodule StreamBoundaryError do
    defexception [:message]
  end
end
