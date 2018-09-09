defmodule PBFParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :pbf_parser,
      version: "0.1.1",
      elixir: ">= 1.7.0",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      name: "PBF Parser",
      source_url: "https://github.com/mpraski/pbf-parser"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:exprotobuf, "~> 1.2"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Elixir parser and decoder for OpenStreetMap PBF format described in PBF file specification."
  end

  defp docs do
    [
      main: "PBFParser",
      extras: ["README.md"]
    ]
  end

  defp package do
    [
      files: ~w(lib config .formatter.exs mix.exs README* LICENSE*
                CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mpraski/pbf-parser"}
    ]
  end
end
