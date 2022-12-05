defmodule PostgrexWal.MixProject do
  use Mix.Project

  def project do
    [
      app: :postgrex_wal,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
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

  defp elixirc_paths(:test), do: ["lib", "test"]
  defp elixirc_paths(:prod), do: ["lib", "release_tasks"]
  defp elixirc_paths(:dev), do: ["lib"]
end
