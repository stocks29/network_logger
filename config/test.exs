use Mix.Config

config :logger, :network_logger,
  level: :debug

config :logger,
  backends: [
    {Logger.Backends.Network, :test}
  ]
