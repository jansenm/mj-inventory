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

defmodule MJ.Inventory.MergeTest do
  use ExUnit.Case

  alias MJ.Inventory.Blender.Merge

  @moduletag :capture_log

  doctest Merge

  test "module exists" do
    assert is_list(Merge.module_info())
  end


  test "lists won't work" do
    assert Merge.deep_merge(
             [1, 2, 3],
             [4, 5, 6]
           ) == {[1, 2, 3, 4, 5, 6], []}
  end

  test "merge additional key -> values into left" do
    assert Merge.deep_merge(
             %{a: 1, b: 2},
             %{c: 3}
           ) == {%{a: 1, b: 2, c: 3}, []}
  end

  test "overwrite values for non sequential types" do
    assert Merge.deep_merge(
             %{a: 1, b: 2},
             %{a: 3}
           ) == {%{a: 3, b: 2}, []}
  end

  test "merge nested maps" do
    assert Merge.deep_merge(
             %{
               a: %{
                 aa: 1
               }
             },
             %{
               a: %{
                 ab: 2
               }
             }
           ) == {
             %{
               a: %{
                 aa: 1,
                 ab: 2
               }
             },
             []
           }
  end

  test "explicitly overwrite nested maps" do
    assert Merge.deep_merge(
             %{
               "a" => %{
                 aa: 1
               }
             },
             %{
               "~a" => %{
                 ab: 2
               }
             }
           ) == {
             %{
               "a" => %{
                 ab: 2
               }
             },
             []
           }
  end


  test "append lists" do
    assert Merge.deep_merge(
             %{a: [1, 2, 3]},
             %{a: [4, 5, 6]}
           ) == {%{a: [1, 2, 3, 4, 5, 6]}, []}
  end

  test "overwrite lists" do
    assert Merge.deep_merge(
             %{"a" => [1, 2, 3]},
             %{"~a" => [4, 5, 6]}
           ) == {%{"a" => [4, 5, 6]}, []}
  end

end