# SPDX-FileCopyrightText: 2021 2021 Michael Jansen <info@michael-jansen.biz>
#
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Copyright (C) 2021 Michael Jansen <info@michael-jansen.biz>
#
# This software is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This software is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>. 

defmodule MJ.InventoryWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MJ.InventoryWeb.Telemetry,
      # Start the Endpoint (http/https)
      MJ.InventoryWeb.Endpoint,
      # Start one inventory
      %{
        id: MJ.Inventory,
        start: {MJ.Inventory, :start_link, [[], [name: MJ.Inventory]]}
      }
      # {
      #   DynamicSupervisor,
      #   [name: MJ.InventoryWeb.InventoriesSupervisor, strategy: :one_for_one]
      #   # added missing piece
      # },
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MJ.InventoryWeb.Supervisor]
    {:ok, pid} = Supervisor.start_link(children, opts)

    opts = Application.get_env(:inventory_web, :repository)
    MJ.Inventory = MJ.Inventory.Repository.load(MJ.Inventory, opts)
    {:ok, pid}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MJ.InventoryWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
