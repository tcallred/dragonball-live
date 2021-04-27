# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :dragonball, DragonballWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "oDIwt2RE0h15sAllyX5qt+Zg4AOADz2oExNsOx4n9YIitysbt1aTPMSJj2IEWfvt",
  render_errors: [view: DragonballWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Dragonball.PubSub,
  live_view: [signing_salt: "aPK4MaI0"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
