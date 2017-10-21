Elixir Network Logger
==================

Network Logger is a logger backend that outputs elixir logs to tcp/udp

Most of it was shamelessly copied from json_logger.

## Configuration

Network Logger currently provides very few options:

* __level__: The minimal level of logging. There's no default of this option. Example: `level: :warn`
* __output__: The output of the log. Must be either `:console` or `{:udp, host, port}` or `{:tcp, host, port}`. Example: `output: {:udp, "localhost", 514}`
* __metadata__: Keys from the metadata to log. Example: `metadata: [:pid]`
* __format__: Format of the log file. Example: `"$time $metadata[$level] $message\n"` (default)

Example configuration:

```elixir
config :logger, :network_logger,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:pid, :module],
  output: {:udp, "localhost", 514}
```

**TCP support is still experimental, please submit issues that you encounter.**

### Adding the logger backend

You need to add this backend to your `Logger`:

```elixir
# in your config...
config :logger,
  backends: [
    Logger.Backends.Network,
  ]

# or, in your code...
Logger.add_backend Logger.Backends.Network
```
