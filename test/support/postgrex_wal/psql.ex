defmodule PostgrexWal.PSQL do
  @moduledoc false

  @pg_env %{
    "PGUSER" => "postgres",
    "PGDATABASE" => "postgres"
  }

  def cmd(query) do
    args = ["-c", query]
    {output, status} = System.cmd("psql", args, stderr_to_stdout: true, env: @pg_env)

    if status != 0 do
      IO.puts("""
      Command:

      psql #{Enum.join(args, " ")}

      error'd with:

      #{output}

      Please verify the user "postgres" exists and it has permissions to
      create databases and users. If not, you can create a new user with:

      $ createuser postgres -s --no-password
      """)

      System.halt(1)
    end

    output
  end
end