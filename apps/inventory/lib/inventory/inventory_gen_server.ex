defmodule MJ.Inventory.GenServer do
  @moduledoc false
  use GenServer

  require Logger

  @impl GenServer
  def init(config) do
    {storage, config} = Keyword.pop(config, :storage)

    if config != [] do
      raise "init: unknown parameters encountered #{inspect(config)}}"
    end

    {:ok, %{storage: storage}}
  end

  @impl GenServer
  def handle_call(_msg, _from, state) do
    {:reply, {:error, :not_implemented}, state}
  end
end
