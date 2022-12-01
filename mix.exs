defmodule PostgrexWal.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrex_wal,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      env: [
        db_conn_info: [
          host: "localhost",
          database: "r704_development",
          username: "jswk"
        ]
      ],
      extra_applications: [:logger],
      mod: {PostgrexWal.Application, []}
    ]
  end

  defp deps do
    [
      {:postgrex, "~> 0.16"},
      {:typed_struct, "~> 0.3.0"},
      {:gen_stage, "~> 1.0.0"},
      {:pgoutput_decoder, "~> 0.1.0"}
    ]
  end
end
