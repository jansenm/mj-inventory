defmodule MJ.Inventory do
  @moduledoc """
  MJ.Inventory API.
  """

  @behaviour MJ.Inventory.Behaviour

  @server MJ.Inventory.GenServer

  @doc """
    :TODO:
  """
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [@server, init_arg]}
    }
  end

  @doc """
  %%  :TODO: Share with behaviour
  """
  @impl MJ.Inventory.Behaviour
  def init(server) do
    case GenServer.call(server, :init) do
      {:ok} -> {:ok, server}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    :TODO: Share with behaviour
  """
  @impl MJ.Inventory.Behaviour
  def list(_server, _type) do
    {:error, :not_implemented}
  end

  @doc """
    :TODO: Share with behaviour
  """
  @impl MJ.Inventory.Behaviour
  def get(_server, _elem, _version) do
    {:error, :not_implemented}
  end

  @doc """
    :TODO: Share with behaviour
  """
  @impl MJ.Inventory.Behaviour
  def repo(_server) do
    {:error, :not_implemented}
  end
end
