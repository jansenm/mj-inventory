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

defmodule DependencyTest do
  use ExUnit.Case

  alias MJ.Inventory.Dependency

  @moduletag :capture_log

  doctest Dependency

  test "module exists" do
    assert is_list(Dependency.module_info())
  end

  test "can add dependencies" do
    d = Dependency.new()
        |> Dependency.add({:class, "base1"}, {:class, "base2"})
        |> Dependency.add({:class, "base2"}, {:node, "node2"})
        |> Dependency.add({:class, "base2"}, {:node, "node1"})

    assert [{:class, "base1"}, {:class, "base2"}, {:node, "node1"}, {:node, "node2"}] == Dependency.topsort(d)
  end

  test "can get subgraph" do
    d = Dependency.new()
        |> Dependency.add({:class, "base1"}, {:class, "base2"})
        |> Dependency.add({:class, "base2"}, {:node, "node2"})
        |> Dependency.add({:class, "base2"}, {:node, "node1"})
        |> Dependency.subgraph([{:class, "base2"}, {:node, "node2"}, {:node, "node1"}])

    assert [{:class, "base2"}, {:node, "node1"}, {:node, "node2"}] == Dependency.topsort(d)
  end
end
