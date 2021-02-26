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

defmodule MJ.InventoryWeb.InventoryLive do
  use MJ.InventoryWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, type: nil, name: nil, index: "nodes", inventory: MJ.Inventory)}
  end

  @impl true
  def handle_params(params, uri, socket) do
    handle_params(socket.assigns.live_action, params, uri, socket)
  end

  defp handle_params(:show_class, params, _uri, socket) do
    case MJ.Inventory.get(socket.assigns.inventory, {:class, params["name"]}) do
      {:ok, class} ->
        {:ok, computed_values} = MJ.Inventory.get(socket.assigns.inventory, {:class, params["name"]}, :computed)
        inheritance_path = MJ.Inventory.get(socket.assigns.inventory, {:class, params["name"]}, :inheritance_path)
        inheritance_values = MJ.Inventory.get(socket.assigns.inventory, {:class, params["name"]}, :computed_all)
        badges = MJ.Inventory.get(socket.assigns.inventory, {:class, params["name"]}, :badges)
        {
          :noreply,
          assign(
            socket,

            badges: badges,
            computed_values: computed_values,
            inheritance_path: inheritance_path,
            inheritance_values: inheritance_values,
            name: class.name,
            object: class,
            tab: "definition",
            type: "class",
            page_title: "class #{class.name}"
          )
        }
      {:error, :not_found} ->
        {
          :noreply,
          assign(
            socket,
            badges: [],
            inheritance_path: nil,
            inheritance_values: nil,
            name: params["name"],
            object: nil,
            tab: "definition",
            type: "class",
            page_title: "class #{params["name"]}"
          )
        }

    end
  end

  defp handle_params(:show_node, params, _uri, socket) do
    case MJ.Inventory.get(socket.assigns.inventory, {:node, params["name"]}) do
      {:ok, node} ->
        {:ok, computed_values} = MJ.Inventory.get(socket.assigns.inventory, {:node, params["name"]}, :computed)
        inheritance_path = MJ.Inventory.get(socket.assigns.inventory, {:node, params["name"]}, :inheritance_path)
        inheritance_values = MJ.Inventory.get(socket.assigns.inventory, {:node, params["name"]}, :computed_all)
        badges = MJ.Inventory.get(socket.assigns.inventory, {:node, params["name"]}, :badges)
        {
          :noreply,
          assign(
            socket,
            badges: badges,
            computed_values: computed_values,
            inheritance_path: inheritance_path,
            inheritance_values: inheritance_values,
            name: params["name"],
            object: node,
            tab: "definition",
            type: "node",
            page_title: "node #{node.name}"
          )
        }
      {:error, :not_found} ->
        {
          :noreply,
          assign(
            socket,
            badges: [],
            inheritance_path: nil,
            inheritance_values: nil,
            name: params["name"],
            object: nil,
            tab: "definition",
            title: "Node #{params["name"]}",
            type: "node",
            page_title: "node #{params["name"]}"
          )
        }
    end
  end

  defp handle_params(:index_classes, _params, _uri, socket) do
    {
      :noreply,
      socket
      |> socket_remove_object
      |> assign(
           objects: MJ.Inventory.get_names_and_badges(socket.assigns.inventory, :class),
           title: "Classes",
           type: "class",
           page_title: "classes"
         )
    }
  end

  defp handle_params(:index_nodes, _params, _uri, socket) do
    {
      :noreply,
      socket
      |> socket_remove_object
      |> assign(
           objects: MJ.Inventory.get_names_and_badges(socket.assigns.inventory, :node),
           title: "Nodes",
           type: "node",
           page_title: "nodes"
         )
    }
  end

  defp handle_params(:index_errors, _params, _uri, socket) do
    {
      :noreply,
      socket
      |> socket_remove_object
      |> assign(
           errors: MJ.Inventory.errors(socket.assigns.inventory),
           title: "Errors",
           page_title: "errors"
         )
    }
  end

  defp handle_params(:reload, _params, _uri, socket) do
    opts = Application.get_env(:inventory_web, :repository)
    MJ.Inventory = MJ.Inventory.Repository.load(MJ.Inventory, opts)
    {:noreply, push_patch(socket, to: Routes.inventory_path(socket, :index_errors), replace: true)}
  end

  @impl true
  def handle_event("show", value, socket) do
    tab = Map.get(value, "tab", "definition")
    {:noreply, assign(socket, tab: tab)}
  end

  defp socket_remove_object(socket) do
    socket
    |> assign(objects: nil)
    |> assign(badges: nil)
    |> assign(computed_values: nil)
    |> assign(inheritance_path: nil)
    |> assign(inheritance_values: nil)
    |> assign(name: nil)
    |> assign(object: nil)
    |> assign(tab: nil)
    |> assign(type: nil)
  end

end
