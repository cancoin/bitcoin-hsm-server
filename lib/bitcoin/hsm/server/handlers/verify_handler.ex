defmodule Bitcoin.HSM.Server.Handlers.VerifyHandler do

  @moduledoc """
  """

  def command, do: :verify

  def transform_args(%{public_key: pubkey, hash: hash, signature: signature}) do
    case Base.decode16(pubkey, case: :lower) do
      {:ok, pubkey} ->
        case Base.decode16(hash, case: :lower) do
          {:ok, hash} ->
            case Base.decode16(signature, case: :lower) do
              {:ok, signature} ->
                {:ok, [pubkey, hash, signature]}
              :error ->
                {:error, :invalid_base16}
            end
          :error ->
            {:error, :invalid_base16}
        end
      :error ->
        {:error, :invalid_base16}
    end
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(valid) do
    {:ok, %{valid: valid}}
  end

end




