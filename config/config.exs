# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :croc,
  ecto_repos: [Croc.Repo]

# Configures the endpoint
config :croc, CrocWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "hX2t02Ej/xqLIwVuUlsBkbpv01ypLhqKtEbRrfnYB/q/WAfbjh3j1hIr96qWuO6O",
  render_errors: [view: CrocWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Croc.PubSub, adapter: Phoenix.PubSub.PG2]

# Phauxth authentication configuration
config :phauxth,
  user_context: Croc.Accounts,
  crypto_module: Argon2,
  token_module: CrocWeb.Auth.Token

# Mailer configuration
config :croc, CrocWeb.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: System.get_env("SENDGRID_KEY")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :mnesia,
  dir: '.mnesia/#{Mix.env()}/#{node()}'

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
