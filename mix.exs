defmodule QrzEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :qrz_ex,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.2.0"},
      {:hackney, "~> 1.14.0"},
      {:sweet_xml, "~> 0.6.6"}
    ]
  end
end
