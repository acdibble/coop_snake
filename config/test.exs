import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :coop_snake, CoopSnakeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cvBmv43qE6MpXAOC/uNUA4jd6Lt0mTEtpPP3446/ImaNmyNEkM3vR3qYQgJn/GLl",
  server: false

# In test we don't send emails.
config :coop_snake, CoopSnake.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
