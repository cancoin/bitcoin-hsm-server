defmodule Bitcoin.HSM.Server.Handlers.SignHandler do

  @moduledoc """
  """

  def command, do: :sign

  def transform_args(%{epk: epk, hash: hash} = p) do
    case Base.decode16(epk, case: :lower) do
      {:ok, epk} ->
        case Base.decode16(hash, case: :lower) do
          {:ok, hash} ->
            {:ok, [epk, hash]}
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

  def transform_reply(signature) do
    {:ok, %{signature:  Base.encode16(signature, case: :lower)}}
  end

end



