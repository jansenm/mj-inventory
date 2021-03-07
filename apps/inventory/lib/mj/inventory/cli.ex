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

defmodule MJ.Inventory.CLI do
  alias MJ.Inventory.Types.Node

  def main(args) do
    options = [
      strict: [
        help: :boolean,
        version: :boolean,
        list: :boolean,
        host: :string,
      ],
      aliases: [
      ]
    ]

    try do
      case OptionParser.parse(args, options) do
        {opts, args, []} ->
          opts
          |> handle_opts()
          |> handle_args(args)
        {_, _, invalid} ->
          # credo:disable-for-next-line Credo.Check.Warning.IoInspect
          IO.inspect(invalid)
          usage()
      end
    rescue
      e in MJ.Error -> IO.puts(e.message)
    end
  end

  def handle_opts(opts) do
    opts
    |> Enum.reduce(%{}, fn {opt, val}, acc -> handle_opt(acc, opt, val) end)
  end

  def handle_opt(opts, :list, true) do
    Map.put(opts, :action, :list)
  end

  def handle_opt(opts, :host, host) do
    Map.put(opts, :action, {:host, host})
  end

  def handle_opt(_opts, :help, true) do
    usage()
    System.halt(0)
  end

  def handle_opt(opts, :version, true) do
    opts
  end

  def handle_args(opts, args) do
    action(Map.get(opts, :action, :inventory), opts, args)
  end

  def action(:list, _opts, args) do
    {:ok, inventory} = MJ.Inventory.start_link([])
    inventory = MJ.Inventory.Repository.load(
      inventory,
      [
        type: :file,
        path: List.first(args)
      ]
    )
    config = gather_classes(inventory)
    IO.puts(
      Jason.encode!(config, pretty: true)
    )
  end

  def action({:host, host}, _opts, args) do
    {:ok, inventory} = MJ.Inventory.start_link([])
    inventory = MJ.Inventory.Repository.load(
      inventory,
      [
        type: :file,
        path: List.first(args)
      ]
    )
    host = get_node(inventory, host)
    IO.puts(
      Jason.encode!(host.parameters, pretty: true)
    )
  end


  def action(:inventory, _opts, args) do
    if Enum.count(args) != 1 do
      IO.puts("error:exactly one argument expected")
      System.halt(1)
    end

    {:ok, inventory} = MJ.Inventory.start_link([])
    inventory = MJ.Inventory.Repository.load(
      inventory,
      [
        type: :file,
        path: List.first(args)
      ]
    )
    IO.puts("has_errors: #{MJ.Inventory.has_errors?(inventory)}")

    config = %{
      applications: %{},
      nodes: gather_nodes(inventory),
      classes: gather_classes(inventory)
    }

    IO.puts(
      Jason.encode!(config, pretty: true)
    )
  end

  def gather_classes(inventory) do
    classes = all_nodes(inventory)
              |> Enum.map(
                   fn node ->
                     MJ.Inventory.get(inventory, {:node, node.name}, :inheritance_path)
                     |> Enum.map(fn base -> {node.name, base} end)
                   end
                 )
              |> List.flatten()
              |> Enum.group_by(fn {_, base} -> base end, fn {name, _} -> name end)
      # I want the result to be easily comparable. So lets do some sorting
              |> Enum.map(fn {class, nodes} -> {class, Enum.sort(nodes)} end)
              |> Enum.into(%{})
    classes
  end

  def get_node(inventory, name) do
    case MJ.Inventory.get(inventory, {:node, name}, :computed) do
      {:ok, %Node{valid?: false} = node} ->
        IO.puts(:stderr, "error:node >#{node.name}< has errors")
        node.messages
        |> Enum.filter(fn msg -> msg.severity == :error end)
        |> Enum.each(fn msg -> IO.puts(:stderr, "   #{msg.message}") end)
        System.halt(1)
      {:ok, %Node{} = node} ->
        node
      {:error, :not_found} ->
        IO.puts(:stderr, "error:node >#{name}< not defined")
        System.halt(1)
    end
  end

  def all_nodes(inventory) do
    MJ.Inventory.get_names(inventory, :node)
    |> Enum.map(fn name -> get_node(inventory, name) end)
  end

  def gather_nodes(inventory) do
    for node <- all_nodes(inventory) do
      classes = MJ.Inventory.get(inventory, {:node, node.name}, :inheritance_path)
      {
        node.name,
        %{
          applications: node.applications,
          classes: classes
                   |> Enum.sort(),
          parameters: node.parameters
        }
      }
    end
    |> Enum.into(%{})
  end

  def usage() do
    IO.puts """
    TODO USAGE
    """
  end
end