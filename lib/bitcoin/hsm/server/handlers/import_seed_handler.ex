defmodule Bitcoin.HSM.Server.Handlers.ImportSeedHandler do

  @moduledoc """
  """

  def command, do: :import_seed

  def transform_args(%{seed: seed}) do
    case Base.decode16(seed, case: :lower) do
      {:ok, seed} ->
        {:ok, [seed]}
      :error ->
        {:error, :invalid_base16}
    end
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(epk) do
    {:ok, %{epk: Base.encode16(epk, case: :lower)}}
  end

end



