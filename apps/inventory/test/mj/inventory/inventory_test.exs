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

defmodule MJ.InventoryTest do
  use ExUnit.Case
  doctest MJ.Inventory

  alias MJ.Inventory
  alias MJ.Inventory.Types.Message

  # @moduletag :capture_log

  def create_inventory(_) do
    {:ok, pid} = start_supervised(Inventory)
    ^pid = MJ.Inventory.Repository.load(pid, [type: :empty])
    [inventory: pid]
  end

  describe "the inventory" do

    setup [:create_inventory]

    test "class: stores definition", %{inventory: inventory} do
      class1 = TestHelper.define_one(
        """
        ---
        type: class
        name: class1
        """
      )
      Inventory.put(inventory, class1)
      assert {:ok, ^class1} = Inventory.get(inventory, {:class, "class1"})
    end

    test "class: computes inheritance path", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        ---
        type: class
        name: base1
        ---
        type: class
        name: base2
        classes: [ base1 ]
        ---
        type: class
        name: class1
        classes: [ base2 ]
        """,
        inventory
      )
      ["base1", "base2"] = Inventory.get(inventory, {:class, "class1"}, :inheritance_path)
    end

    test "class: does not interpolates values", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        type: class
        name: class1
        parameters:
          greeting: Hello ${name}
        """,
        inventory
      )
      {:ok, class1} = Inventory.get(inventory, {:class, "class1"}, :computed)
      assert class1.parameters["greeting"] == "Hello ${name}"
    end

    test "class: can handle valid yaml but invalid class specification", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        type: class
        name: class1
        # notice the typo
        parameteras:
          greeting: Hello ${name}
        """,
        inventory
      )
      {:ok, class1} = Inventory.get(inventory, {:class, "class1"}, :computed)
      assert class1.valid? == false
      assert class1.parameters == nil
      assert class1.messages == [%Message{severity: :error, message: "parsing error:unknown section »parameteras«"}]
    end

    test "node: stores definition", %{inventory: inventory} do
      node1 = TestHelper.define_one(
        """
        ---
        type: node
        name: node1
        """
      )
      Inventory.put(inventory, node1)
      assert {:ok, ^node1} = Inventory.get(inventory, {:node, "node1"})
    end

    test "node: computes inheritance path", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        ---
        type: class
        name: base1
        ---
        classes: [ base1 ]
        type: node
        name: node1
        """,
        inventory
      )
      ["base1"] = Inventory.get(inventory, {:node, "node1"}, :inheritance_path)
    end

    test "nodes: interpolates values", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        type: node
        name: node1
        parameters:
          name: Michael
          greeting: Hello ${name}
        """,
        inventory
      )
      {:ok, node1} = Inventory.get(inventory, {:node, "node1"}, :computed)
      assert node1.parameters["greeting"] == "Hello Michael"
    end

    test "node: can handle valid yaml but invalid node specification", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        type: node
        name: node1
        # notice the typo
        parameteras:
          greeting: Hello ${name}
        """,
        inventory
      )
      {:ok, node1} = Inventory.get(inventory, {:node, "node1"}, :computed)
      assert node1.valid? == false
      assert node1.parameters == nil
      assert node1.messages == [%Message{severity: :error, message: "parsing error:unknown section »parameteras«"}]
    end

    test "node: can compute values", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        ---
        type: class
        name: base1
        parameters:
          motd: "hello world"
        ---
        type: node
        name: node1
        classes:
          - base1
        """,
        inventory
      )
      {:ok, node1} = Inventory.get(inventory, {:node, "node1"}, :computed)
      ["base1"] = Inventory.get(inventory, {:node, "node1"}, :inheritance_path)
      assert node1.parameters["motd"] == "hello world"
    end

    test "caching doesn't screw up", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        ---
        type: class
        name: base1
        parameters:
          motd: "Hello from ${name}"
          name: base1
        ---
        type: class
        name: base2
        classes: [ base1 ]
        ---
        type: node
        name: node1
        classes: [ base2 ]
        """,
        inventory
      )
      {:ok, node1} = Inventory.get(inventory, {:node, "node1"}, :computed)
      assert node1.parameters["motd"] == "Hello from base1"
      {:ok, base2} = Inventory.get(inventory, {:class, "base2"}, :computed)
      assert base2.parameters["name"] == "base1"

      TestHelper.register_inventory(
        """
        ---
        type: class
        name: base2
        classes: [ base1 ]
        parameters:
          name: base2
        """,
        inventory
      )
      {:ok, node1} = Inventory.get(inventory, {:node, "node1"}, :computed)
      assert node1.parameters["motd"] == "Hello from base2"
      {:ok, base2} = Inventory.get(inventory, {:class, "base2"}, :computed)
      assert base2.parameters["name"] == "base2"
    end

    test "correctly returns complete history", %{inventory: inventory} do
      TestHelper.register_inventory(
        """
        ---
        type: class
        name: base1
        parameters:
          a: 1
        ---
        type: class
        name: base2
        classes: [ base1 ]
        parameters:
          a: 2
          b: 3
        ---
        type: class
        name: class1
        classes: [ base2 ]
        parameters:
          a: 3
          c: 4
        """,
        inventory
      )
      all = Inventory.get(inventory, {:class, "class1"}, :computed_all)
      assert Enum.count(all) == 3
      [ok: base1, ok: base2, ok: class1] = all
      assert base1.name == "base1"
      assert base1.parameters == %{"a" => 1}
      assert base2.name == "base2"
      assert base2.parameters == %{"a" => 2, "b" => 3}
      assert class1.name == "class1"
      assert class1.parameters == %{"a" => 3, "b" => 3, "c" => 4}
    end

  end
end
