# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

config :saitama, SaitamaWeb.Endpoint,
  # Possibly not needed, but doesn't hurt
  http: [port: {:system, "PORT"}],
  url: [host: (System.get_env("RENDER_EXTERNAL_HOSTNAME") || "") <> ".gigalixirapp.com", port: 80],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  server: true

config :saitama, Saitama.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  ssl: true,
  pool_size: 2
