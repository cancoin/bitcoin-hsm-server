use Mix.Config

config :bitcoin_hsm_server,
  port: 7070,
  bind: "127.0.0.1",
  pidfile: "/tmp/bitcoin_hsm_server.pid"

config :sasl,
  errlog_type: :error
