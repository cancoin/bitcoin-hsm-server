defmodule Bitcoin.HSM.Server.Supervisor do
  use Supervisor

  @doc false
  def start_link(config) do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [config])
  end

  def init([config]) do
    children = [
    ]
    supervise children, strategy: :one_for_one
  end
end

