defmodule Cerebrum.Mixfile do
  use Mix.Project

  def project do
    [app: :cerebrum,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(Mix.env)]
  end
  def application do
    [applications: [:logger, :neo4j_sips, :con_cache]]
  end

  defp deps(:test) do
    deps(:prod) ++
    [
      {:eye_drops, "~> 1.0.1"},
      {:credo, "~> 0.3.8"},
      {:mock, "~> 0.1.1", only: :test}
    ]
  end

  defp deps(:prod) do
    [
      {:exalgebra, "~> 0.0.4"},
      {:neo4j_sips, "~> 0.1"},
      {:con_cache, "~> 0.11.0"}
    ]
  end

  defp deps(_) do
    deps(:test) ++ []
  end

end
