defmodule Bitcoin.HSM.Server.Handlers.ExtendedPublicKeyHandler do

  @moduledoc """
  """

  def command, do: :public_key

  def transform_args(%{epk: epk}) do
    case Base.decode16(epk, case: :lower) do
      {:ok, epk} ->
        {:ok, [epk]}
      :error ->
        {:error, :invalid_base16}
    end
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(public_key) do
    extended_public_key = Bitcoin.HSM.serialize_public_key(public_key)
    {:ok, %{extended_public_key: extended_public_key}}
  end

end




