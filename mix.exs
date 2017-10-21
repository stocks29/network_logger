defmodule Logger.Backends.JSON.Mixfile do
  use Mix.Project

  def project do
    [app: :network_logger,
     version: "0.0.1",
     elixir: ">= 1.0.0",
     deps: deps(),
     description: "A simple library for logging over the network.",
     package: package(),
     source_url: "https://github.com/stocks29/network_logger"]
  end

  def application, do: [
    extra_applications: [:logger],
  ]

  defp deps do
    [{:ex_doc, ">= 0.0.0", only: :dev}]
  end

  def package do
    [
      maintainers: ["Bob Stockdale"],
      licenses: ["Apache License 2.0"],
      links: %{"GitHub" => "https://github.com/stocks29/network_logger"}
    ]
  end
end
