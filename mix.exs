defmodule APNSx.Mixfile do
  use Mix.Project

  def project do
    [app: :apnsx,
     name: "APNSx",
     source_url: "https://github.com/jnbt/apnsx",
     version: "0.0.1-dev",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     docs: [extras: ["README.md"]]]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:mix_test_watch, "~> 0.2", only: :dev},
     {:ex_doc, "~> 0.11", only: :docs},
     {:inch_ex, "~> 0.5", only: :docs}]
  end
end
