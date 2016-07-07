defmodule Bitcoin.HSM.Server.Handlers.ImportWIFHandler do

  @moduledoc """
  """

  def command, do: :import_wif

  def transform_args(%{wif: wif}) do
    {:ok, [wif]}
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(epk) do
    {:ok, %{epk: Base.encode16(epk, case: :lower)}}
  end

end


