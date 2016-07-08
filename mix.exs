defmodule Bitcoin.HSM.Server.Mixfile do
  use Mix.Project

  def project do
    [app: :bitcoin_hsm_server,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps ++ deps(Mix.env)]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [
      :logger, :cowboy, :exjsx,
      :gproc, :base58,
      :bitcoin_hsm, :libbitcoin],
     mod: {Bitcoin.HSM.Server, []}]
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
      {:exrm, "~> 0.19.8"},
      {:exjsx, "~> 3.2.0"},
      {:gproc, "~> 0.5.0"},
      {:ranch, "~> 1.1.0", override: true},
      {:cowlib, "~> 1.3.0", override: true},
      {:cowboy, github: "ninenines/cowboy", ref: "2.0.0-pre.3"},
      {:libbitcoin, github: "cancoin/libbitcoin-nif"},
      {:bitcoin_hsm, path: "cancoin/bitcoin-hsm"},
      {:base58, github: "cancoin/erl-base58"}
    ]
  end

  defp deps(:test) do
    [
      {:gun, github: "ninenines/gun", ref: "master"}
    ]
  end
  defp deps(_), do: []
end
