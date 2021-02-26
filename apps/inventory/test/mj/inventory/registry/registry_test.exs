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

defmodule MJ.Inventory.RegistryTest do
  use ExUnit.Case

  alias MJ.Inventory.Registry

  # @moduletag :capture_log

  doctest Registry


  test "module exists" do
    assert is_list(Registry.module_info())
  end

  describe "Registry" do

    setup do
      {:ok, registry: MJ.Inventory.Registry.new()}
    end

    test "classes and nodes are distinct", %{registry: registry} do
      # the registry is empty
      assert Registry.get(registry, {:class, "laptop"}) == {:error, :not_found}
      assert Registry.get(registry, {:node, "laptop"}) == {:error, :not_found}
      assert Registry.get_names(registry, :node) == []
      assert Registry.get_names(registry, :class) == []
      # we add a node
      TestHelper.register(
        """
        ---
        type: node
        name: laptop
        parameters:
          description: my personal laptop
        """,
        registry
      )
      # the registry contains the node but no classes.
      assert Registry.get(registry, {:class, "laptop"}) == {:error, :not_found}
      assert Registry.get(registry, {:node, "laptop"}) != {:error, :not_found}
      assert Registry.get_names(registry, :node) == ["laptop"]
      assert Registry.get_names(registry, :class) == []
      # we add a class with the same name as the node
      TestHelper.register(
        """
        ---
        type: class
        name: laptop
        parameters:
          description: a portable computer
        """,
        registry
      )
      # the registry contains both
      assert Registry.get_names(registry, :node) == ["laptop"]
      assert Registry.get_names(registry, :class) == ["laptop"]

      # there is no confusion between the class ...
      {:ok, classlaptop} = Registry.get(registry, {:class, "laptop"})
      assert classlaptop != nil
      assert classlaptop.parameters != nil
      assert classlaptop.parameters["description"] == "a portable computer"

      # there is no confusion between the class ... and node
      assert Registry.get_names(registry, :node) == ["laptop"]
      {:ok, nodelaptop} = Registry.get(registry, {:node, "laptop"})
      assert nodelaptop != nil
      assert nodelaptop.parameters != nil
      assert nodelaptop.parameters["description"] == "my personal laptop"
    end

    test "remove_all()", %{registry: registry} do
      # registry is empty
      assert Registry.get_names(registry, :node) == []
      assert Registry.get_names(registry, :class) == []
      # we add some stuff
      TestHelper.register(
        """
        ---
        type: class
        name: laptop
        ---
        type: node
        name: laptop
        """,
        registry
      )
      # the stuff is there
      assert Registry.get_names(registry, :node) == ["laptop"]
      assert Registry.get_names(registry, :class) == ["laptop"]
      # we remove the stuff
      Registry.remove_all(registry)
      # the registry is empty
      assert Registry.get_names(registry, :node) == []
      assert Registry.get_names(registry, :class) == []
    end

    test "remove()", %{registry: registry} do
      # registry is empty
      assert Registry.get_names(registry, :node) == []
      assert Registry.get_names(registry, :class) == []
      # we add some stuff
      TestHelper.register(
        """
        ---
        type: class
        name: laptop
        ---
        type: node
        name: laptop
        """,
        registry
      )
      # the stuff is there
      assert Registry.get_names(registry, :node) == ["laptop"]
      assert Registry.get_names(registry, :class) == ["laptop"]
      # we remove the class
      Registry.remove(registry, {:class, "laptop"})
      assert Registry.get_names(registry, :node) == ["laptop"]
      assert Registry.get_names(registry, :class) == []
      # We remove the node
      Registry.remove(registry, {:node, "laptop"})
      assert Registry.get_names(registry, :node) == []
      assert Registry.get_names(registry, :class) == []
    end
  end
end

