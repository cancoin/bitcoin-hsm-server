defmodule Bitcoin.HSM.Server.Handlers.DeriveHandler do

  @moduledoc """
  """

  def command, do: :derive

  def transform_args(%{epk: epk, key_path: path}) do
    case Base.decode16(epk, case: :lower) do
      {:ok, epk} ->
        {:ok, [epk, path]}
      :error ->
        {:error, :invalid_base16}
    end
  end
  def transform_args(_params) do
    IO.inspect "INVALID"
    {:error, :invalid}
  end

  def transform_reply(epk) do
    {:ok, %{epk:  Base.encode16(epk, case: :lower)}}
  end

end


