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

defmodule MJ.Inventory.InheritanceTest do
  use ExUnit.Case
  @moduletag :capture_log

  alias MJ.Inventory.Inheritance
  alias MJ.Inventory.Registry

  doctest Inheritance

  setup do
    {:ok, registry: MJ.Inventory.Registry.new()}
  end

  test "classes and nodes are distinct", %{registry: registry} do

    TestHelper.register(
      """
      ---
      type: class
      name: os
      ---
      type: class
      name: os.linux
      classes:
        - os
      ---
      type: class
      name: distribution
      ---
      type: class
      name: os.opensuse
      classes:
        - os.linux
        - distribution
      ---
      type: node
      name: laptop
      classes:
        - os.opensuse
      parameters:
        description: my personal laptop
      """,
      registry
    )

    assert Inheritance.inheritance_path(
             Registry.get(registry, {:node, "laptop"}) |> elem(1),
             registry
           ) == [
             {:class, "os"},
             {:class, "os.linux"},
             {:class, "distribution"},
             {:class, "os.opensuse"},
             {:node, "laptop"},
           ]

    assert Inheritance.inheritance_path(
             Registry.get(registry, {:class, "os.linux"}) |> elem(1),
             registry
           ) == [
             {:class, "os"},
             {:class, "os.linux"},
           ]

    assert Inheritance.inheritance_path(
             Registry.get(registry, {:class, "distribution"}) |> elem(1),
             registry
           ) == [
             {:class, "distribution"}
           ]
  end

  test "inheriting the same class multiple times", %{registry: registry} do
    TestHelper.register(
      """
      ---
      type: class
      name: baseA
      ---
      type: class
      name: baseB
      classes:
        - baseA
      ---
      type: class
      name: base1
      classes:
        - baseA
      ---
      type: class
      name: baseC
      classes:
        - baseB
        - base1
      ---
      type: node
      name: node1
      classes:
        - baseC
      """,
      registry
    )

    assert Inheritance.inheritance_path(
             Registry.get(registry, {:node, "node1"}) |> elem(1),
             registry
           ) == [
             {:class, "baseA"},
             {:class, "baseB"},
             {:class, "base1"},
             {:class, "baseC"},
             {:node, "node1"},
           ]
  end

  test "circular dependency is detected", %{registry: registry} do
    TestHelper.register(
      """
      ---
      type: class
      name: baseA
      classes:
        - baseC
      ---
      type: class
      name: baseB
      classes:
        - baseA
      ---
      type: class
      name: baseC
      classes:
        - baseB
      """,
      registry
    )

    assert_raise MJ.Inventory.Errors.CircularDependencyError,
                 "Circular dependency detected for class baseC: baseC <- baseA <- baseB <- baseC",
                 fn ->
                   Inheritance.inheritance_path(
                     Registry.get(registry, {:class, "baseC"}) |> elem(1),
                     registry
                   )
                 end

  end

  test "missing base class is detected", %{registry: registry} do
    # Even if the class is not defined we can technically give back a inheritance_path. We just assume
    # the class does have no parents.
    TestHelper.register(
      """
      ---
      type: class
      name: baseB
      classes:
        - baseA
      ---
      type: class
      name: baseC
      classes:
        - baseB
      """,
      registry
    )
    assert Inheritance.inheritance_path(
             Registry.get(registry, {:class, "baseC"}) |> elem(1),
             registry
           ) == [
             {:class, "baseA"},
             {:class, "baseB"},
             {:class, "baseC"}
           ]


  end
end