defmodule PostgrexWal.PSQL do
  @moduledoc """
  psql will use environment variables, suck as: PGDATABASE, PGHOST, PGPASSWORD, PGPORT and/or PGUSER

  Some env variables (as below) has already set in Github traivs CI environment:
  	PGUSER: postgres
  	PGPASSWORD: postgres
  	PG_SOCKET_DIR: /var/run/postgresq
  """

  def cmd(query) do
    env = pg_env()

    database_url =
      "postgres://#{env[:username]}:#{env[:password]}@#{env[:host]}:#{env[:port]}/#{env[:database]}"

    for q <- List.wrap(query) do
      args = [database_url, "-c", q]
      {output, status} = System.cmd("psql", args, stderr_to_stdout: true)

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
    [
      username: System.get_env("PG_USERNAME", "postgres"),
      database: System.get_env("PG_DATABASE", "postgres"),
      host: System.get_env("PG_HOST", "localhost"),
      password: System.get_env("PG_PASSWORD", "postgres"),
      port: System.get_env("PG_PORT", "5432")
    ]
  end
end
