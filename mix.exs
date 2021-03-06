defmodule Croc.MixProject do
  use Mix.Project

  def project do
    [
      app: :croc,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Croc.Application, []},
      extra_applications: [:logger, :runtime_tools, :timex]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.11"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:phauxth, "~> 2.3"},
      {:argon2_elixir, "~> 2.0"},
      {:bamboo, "~> 1.3"},
      {:plug_cowboy, "~> 2.0"},
      {:react_phoenix, "~> 1.1.0"},
      {:memento, "~> 0.3.1"},
      {:elixir_uuid, "~> 1.2"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:opus, "~> 0.6"},
      {:sentry, "~> 7.0"},
      {:distillery, "~> 2.0"},
      {:decimal, "~> 1.0"},
      {:gen_stage, "~> 0.14"},
      {:appsignal, "~> 1.0"},
      {:libcluster, "~> 3.0"},
      # Change github source when pull-request is merged
      {:ex_admin, github: "reetou/ex_admin", branch: "array-float-support"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.0"},
      {:junit_formatter, "~> 3.0", only: [:test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "run test/seeds.exs", "test"]
    ]
  end
end
