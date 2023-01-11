defmodule PostgrexWal.PSQL do
  @moduledoc """
  Defafult env in Github traivs CI environment:
  	PGUSER: postgres
  	PGPASSWORD: postgres
  	PG_SOCKET_DIR: /var/run/postgresq
  """

  @pg_env %{
    "PGUSER" => "postgres",
    "PGDATABASE" => "postgres"
  }

  def cmd(query) do
    query
    |> List.wrap()
    |> Enum.map(fn q ->
      args = ["-c", q, "-h", "localhost"]
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

        raise RuntimeError, "PSQL.cmd error"
      end

      output
    end)
  end
end
