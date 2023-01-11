defmodule PostgrexWal.PSQL do
  @moduledoc """
  psql will use environment variables, suck as: PGDATABASE, PGHOST, PGPASSWORD, PGPORT and/or PGUSER

  Some env variables (as below) has already set in Github traivs CI environment:
  	PGUSER: postgres
  	PGPASSWORD: postgres
  	PG_SOCKET_DIR: /var/run/postgresq
  """

  def cmd(query) do
    for q <- List.wrap(query) do
      args = ["-c", q]
      {output, status} = System.cmd("psql", args, stderr_to_stdout: true, env: pg_env())

      if status != 0 do
        raise """
        Command:

        psql #{Enum.join(args, " ")}

        error'd with:

        #{output}
        """
      end
    end
  end

  def pg_env do
    %{
      "PGUSER" => System.get_env("WAL_USERNAME", "postgres"),
      "PGDATABASE" => System.get_env("WAL_DB", "postgres"),
      "PGHOST" => System.get_env("WAL_HOST", "localhost"),
      "PGPASSWORD" => System.get_env("WAL_PASSWORD", "postgres")
    }
  end
end
