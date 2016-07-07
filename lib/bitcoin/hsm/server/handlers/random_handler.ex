defmodule Bitcoin.HSM.Server.Handlers.RandomHandler do

  @moduledoc """
  """

  def command, do: :random

  def transform_args(%{bytes: bytes}) do
    {:ok, [bytes]}
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(bytes) do
    {:ok, %{random: Base.encode16(bytes, case: :lower)}}

  end

end

