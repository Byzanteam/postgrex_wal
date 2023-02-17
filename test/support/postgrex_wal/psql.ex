defmodule PostgrexWal.PSQL do
  @moduledoc """
  Directly execute SQL statement via `psql` client.
  """

  def cmd(query) do
    url = database_url()

    for q <- List.wrap(query) do
      args = [url, "-c", q]
      {output, status} = System.cmd("psql", args, stderr_to_stdout: true)

      if status != 0 do
        raise """
        Command:

        psql #{Enum.join(args, " ")}

        error'd with:

        #{output}
        """
      end

      output
    end
  end

  def pg_env do
    [
      hostname: System.get_env("PG_HOST", "localhost"),
      port: System.get_env("PG_PORT", "5432"),
      database: System.get_env("PG_DATABASE", "postgres_test"),
      username: System.get_env("PG_USERNAME", "postgres"),
      password: System.get_env("PG_PASSWORD", "postgres")
    ]
  end

  def database_url do
    e = pg_env()
    "postgres://#{e[:username]}:#{e[:password]}@#{e[:hostname]}:#{e[:port]}/#{e[:database]}"
  end
end
