# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :saitama, SaitamaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "xBD+QF/nyf5Q7ayaAcfbQwaC8cB9sb/ul4/J8esQ8enqJM9HYcMRXGnHAIdsT93j",
  render_errors: [view: SaitamaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Saitama.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "6ZH8jx1c4PRY+KY++8rKpGVJn7l0PIZY"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
