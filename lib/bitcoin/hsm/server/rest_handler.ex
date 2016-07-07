defmodule Bitcoin.HSM.Server.RESTHandler do
  alias Bitcoin.HSM.Server.Util

  require Logger

  def init(req, [module]) when is_atom(module) do
    {args, req} = extract_request_params(req)
    case module.transform_args(args) do
      {:error, reason} ->
        req = :cowboy_req.reply(400, [], to_string(reason), req)
        {:ok, req, nil}
      {:ok, args} ->
        {:ok, ref} = send_command(module.command, args)
        {:cowboy_loop, req, %{ref: ref, module: module}, 5000}
    end
  end

# def info({:libbitcoin_client, _command, ref, reply}, req, %{ref: ref, module: module} = state) do
#   case module.transform_reply(reply) do
#     {:ok, reply} ->
#       {:ok, json} = JSX.encode(reply)
#       req = :cowboy_req.reply(200, [], json, req)
#       {:ok, req, state}
#     {:error, reason} ->
#       Logger.debug "transform error #{module}"
#       {:ok, json} = JSX.encode(%{error: reason})
#       {:ok, req} = :cowboy_req.reply(500, [], json, req)
#       {:ok, req, state}
#   end
# end
# def info({:libbitcoin_client_error, command, ref, :timeout}, req, %{ref: ref} = state) do
#   Logger.debug "timeout response  #{command}"
#   {:ok, json} = JSX.encode(%{error: "timeout"})
#   req = :cowboy_req.reply(408, [], json, req)
#   {:ok, req, state}
# end
# def info({:libbitcoin_client_error, command, ref, error}, req, %{ref: ref} = state) do
#   Logger.debug "error response  #{command} #{error}"
#   {:ok, json} = JSX.encode(%{error: error})
#   req = :cowboy_req.reply(500, [], json, req)
#   {:ok, req, state}
# end

  def info({:bitcoin_hsm_reply, ref, reply}, req,  %{ref: ref, module: module} = state) do
    case module.transform_reply(reply) do
      {:ok, reply} ->
        {:ok, json} = JSX.encode(reply)
        req = :cowboy_req.reply(200, [], json, req)
        {:ok, req, state}
      {:error, reason} ->
        Logger.debug "transform error #{module}"
        {:ok, json} = JSX.encode(%{error: reason})
        {:ok, req} = :cowboy_req.reply(500, [], json, req)
        {:ok, req, state}
    end
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  def send_command(command, args) do
    # verify OTP
    async_send_command(self, command, args)
  end

  def async_send_command(owner, command, args) do
    ref = :erlang.make_ref
    pid = spawn fn ->
      case apply(Bitcoin.HSM, command, args) do
        {:ok, reply} ->
          send owner, {:bitcoin_hsm_reply, ref, reply}
        {:error, error} ->
          send owner, {:bitcoin_hsm_error, ref, error}
      end
    end
    {:ok, ref}
  end

  defp extract_request_params(req) do
	  {:ok, [{body, true}], req} = :cowboy_req.body_qs(req)
    case body |> to_string |> JSX.decode do
      {:ok, params} ->
        params_map = Enum.into(params, %{}) |> Util.atomify
        {params_map, req}
      {:error, _} ->
        {%{}, req}
    end
  end

end

