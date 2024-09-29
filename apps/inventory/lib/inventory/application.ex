defmodule Inventory.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  @impl Application
  def start(_type, _args) do
    :ok = :logger.add_handlers(Application.get_application(__MODULE__))
    Logger.info("Application #{Application.get_application(__MODULE__)} started")

    children = [
      # Starts a worker by calling: Inventory.Worker.start_link(arg)
      # {Inventory.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Inventory.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
