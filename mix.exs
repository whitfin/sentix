defmodule Sentix.Mixfile do
  use Mix.Project

  @url_docs "http://hexdocs.pm/sentix"
  @url_github "https://github.com/zackehh/sentix"

  def project do
    [
      app: :sentix,
      name: "Sentix",
      description: "A cross-platform file watcher for Elixir based on fswatch",
      package: %{
        files: [
          "lib",
          "mix.exs",
          "LICENSE",
          "README.md"
        ],
        licenses: [ "MIT" ],
        links: %{
          "Docs" => @url_docs,
          "GitHub" => @url_github
        },
        maintainers: [ "Isaac Whitfield" ]
      },
      version: "1.0.3",
      elixir: "~> 1.2",
      deps: deps(),
      docs: [
        extras: [ "README.md" ],
        source_ref: "master",
        source_url: @url_github
      ],
      test_coverage: [
        tool: ExCoveralls
      ]
   ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [:logger, :cachex],
      included_applications: [:erlexec],
      mod: {Sentix.Application, []},
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      # Production dependencies
      { :cachex,  "~> 2.0" },
      { :erlexec,  "1.2.2" },
      # Development dependencies
      { :credo,       "~> 0.4",  optional: true, only: [ :dev, :test ] },
      { :ex_doc,      "~> 0.12", optional: true, only: [ :dev, :test ] },
      { :excoveralls, "~> 0.5",  optional: true, only: [ :dev, :test ] }
    ]
  end
end
