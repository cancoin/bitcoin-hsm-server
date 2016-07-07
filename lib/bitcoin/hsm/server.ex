defmodule Bitcoin.HSM.Server do
  alias Bitcoin.HSM.Server
  require Logger
  def start(_type, _args) do
    case load_config do
      {:ok, config} ->
        #write_pid!
        Logger.info "Starting HSM Server on port #{config.port}"
        {:ok, _} = :cowboy.start_http(:http, 100,
                                      [port: config.port],
                                      [env: [dispatch: dispatch(config)]])
        Bitcoin.HSM.Server.Supervisor.start_link(config)
      :invalid_configuration ->
        Logger.error "Error starting Bitcoin HSM server"
        exit(:invalid_configuration)
    end
  end

  def dispatch(_config) do
    :cowboy_router.compile([
      {:_, [ { '/api/v1/import/wif', Server.RESTHandler, [Server.Handlers.ImportWIFHandler] },
             { '/api/v1/import/seed', Server.RESTHandler, [Server.Handlers.ImportSeedHandler] },
             { '/api/v1/derive', Server.RESTHandler, [Server.Handlers.DeriveHandler] },
             { '/api/v1/public_key', Server.RESTHandler, [Server.Handlers.PublicKeyHandler] },
             { '/api/v1/extended_public_key', Server.RESTHandler, [Server.Handlers.ExtendedPublicKeyHandler] },
             { '/api/v1/sign', Server.RESTHandler, [Server.Handlers.SignHandler] },
             { '/api/v1/verify', Server.RESTHandler, [Server.Handlers.VerifyHandler] },
             { '/api/v1/random', Server.RESTHandler, [Server.Handlers.RandomHandler] },
             { '/api/v1/websocket', Server.WebSocketHandler, [] },
             {'/', :cowboy_static, {:priv_file, :bitcoin_hsm_server, 'web/build/index.html'}},
             { '/assets/[...]', :cowboy_static, {:priv_dir, :bitcoin_hsm_server, 'web/build'}}
           ] }
     ])
  end

  defp load_config do
    try do
      {:ok, port}     = Application.fetch_env(:bitcoin_hsm_server, :port)
      bind            = Application.get_env(:bitcoin_hsm_server, :bind, "127.0.0.1")
      domain          = Application.get_env(:bitcoin_hsm_server, :domain, :_)
      {:ok, %{
        port: port,
        bind: to_string(bind),
        domain: domain}}
    rescue
      MatchError -> :invalid_configuration
    end
  end

  def write_pid! do
    {:ok, pidfile} = :application.get_env(:bitcoin_hsm_server, :pidfile)
    :ok = File.write(pidfile, :os.getpid)
  end
end

