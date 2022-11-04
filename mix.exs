defmodule UeberauthFastmail.MixProject do
  use Mix.Project

  @version "0.1.0"
  @url "https://github.com/svycal/ueberauth_fastmail"

  def project do
    [
      app: :ueberauth_fastmail,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Ueberauth Fastmail Strategy",
      source_url: @url,
      homepage_url: @url,
      docs: docs(),
      description: description(),
      deps: deps(),
      package: package()
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
      {:oauth2, "~> 1.0 or ~> 2.0"},
      {:ueberauth, "~> 0.7"},
      {:sweet_xml, "~> 0.7.1"},
      {:tesla, "~> 1.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:mox, "~> 0.5", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "LICENSE.md"
      ]
    ]
  end

  defp description do
    "An Überauth strategy for Fastmail authentication."
  end

  defp package do
    [
      maintainers: ["Derrick Reimer"],
      licenses: ["MIT"],
      links: links()
    ]
  end

  def links do
    %{
      "GitHub" => @url,
      "Changelog" => "#{@url}/blob/v#{@version}/CHANGELOG.md",
      "Readme" => "#{@url}/blob/v#{@version}/README.md"
    }
  end
end
