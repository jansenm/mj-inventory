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

defmodule MJ.Inventory.ReclassCompatibilityTest do

  use ExUnit.Case

  # @moduletag :capture_log

  alias MJ.Repository.File, as: FileStore
  alias MJ.Inventory
  doctest FileStore

  @inventories ~w/reclass-compatibility/
                 # @inventories ~w/reclass-other/

  defp create_inventory(_) do
    {:ok, pid} = start_supervised(Inventory)
    ^pid = MJ.Inventory.Repository.load(pid, [type: :empty])
    [inventory: pid]
  end

  defp load_inventory(path, %{inventory: inventory} = _context) do
    FileStore.load(path: Path.expand(path))
    |> Enum.each(fn obj -> Inventory.put(inventory, obj) end)
  end

  defp inventory_path(name), do: "./test/data/#{name}"

  for inventory_name <- @inventories do

    describe "inventory #{inventory_name}" do

      setup [:create_inventory]
      setup(context) do
        load_inventory(inventory_path(unquote(inventory_name)), context)
      end
      setup(_context) do
        TestHelper.load_reclass_inventory(inventory_path(unquote(inventory_name)))
      end

      test "the same classes are defined", %{reclass_config: reclass_config, inventory: inventory} do
        assert reclass_config["classes"]
               |> Map.keys()
               |> Enum.sort() == Inventory.get_names(inventory, :class)
                                 |> Enum.sort()
      end

      test "the same nodes are defined", %{reclass_config: reclass_config, inventory: inventory} do
        assert reclass_config["nodes"]
               |> Map.keys()
               |> Enum.sort() == Inventory.get_names(inventory, :node)
                                 |> Enum.sort()
      end

      # We now load the json during compilation and generate tests for each class and node defined by reclass.
      [reclass_config: reclass_config] = TestHelper.load_reclass_inventory("./test/data/#{inventory_name}")

      for {nodename, _cls} <- reclass_config["nodes"] do
        test "node #{nodename} has correct content", %{reclass_config: reclass_config, inventory: inventory} do
          nodename = unquote(nodename)
          {:ok, node} = Inventory.get(inventory, {:node, nodename}, :computed)
          reclass = get_in(reclass_config, ["nodes", nodename])
          assert node != nil
          assert reclass != nil
          assert node.parameters == reclass["parameters"]
        end
      end

      # TODO: Compare the classes section which lists all nodes that inherit each class.

      # TODO: Write a compatibility output for reclass (reclass --inventory ...)
    end

  end

end
