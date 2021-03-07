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

defmodule MJ.Inventory.BlenderTest do
  use ExUnit.Case

  alias MJ.Inventory.Blender
  alias MJ.Inventory.Types.{Class, Node, Message}

  @moduletag :capture_log

  doctest Blender

  test "module exists" do
    assert is_list(Blender.module_info())
  end

  describe "refuses to blend" do

    test "if left obj is invalid" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", valid?: false},
        %Class{name: "right", valid?: true}
      )
      assert result.name == "right"
      assert result.classes == []
      assert result.applications == nil
      assert result.parameters == nil
      assert result.messages == [%Message{severity: :error, message: "inheritance error:base class left is invalid"}]
    end

    test "if right object is invalid" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", valid?: true},
        %Node{name: "right", valid?: false, messages: [Message.error("invalid yaml")]}
      )
      assert result.name == "right"
      assert result.classes == []
      assert result.applications == nil
      assert result.parameters == nil
      assert result.messages == [%Message{severity: :error, message: "invalid yaml"}]
    end

    test "if left object is node" do
      {:error, :left_is_node, object} =
        Blender.blend(
          %Node{name: "left", valid?: true},
          %Node{name: "right", valid?: true}
        )
      assert object.name == "left"
    end

  end

  describe "returns correct type" do

    test "class and class become class" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", applications: [], valid?: true},
        %Class{name: "right", applications: [], valid?: true}
      )
      assert %Class{} = result
    end

    test "class and node become node" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", applications: [], valid?: true},
        %Node{name: "right", applications: [], valid?: true}
      )
      assert %Node{} = result
    end

  end

  describe "handles applications" do

    test "works with no applications specified" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", valid?: true},
        %Class{name: "right", valid?: true}
      )
      assert result.applications == []
    end

    test "append right.applications to left.applications" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", applications: ["a", "b"], valid?: true},
        %Class{name: "right", applications: ["c", "d"], valid?: true}
      )
      assert result.applications == ["a", "b", "c", "d"]
    end

    test "append right.applications to left.applications (empty)" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", applications: [], valid?: true},
        %Class{name: "right", applications: [], valid?: true}
      )
      assert result.applications == []
    end

  end

  describe "handles parameters" do
    test "deep merges parameters" do
      {:ok, result} = Blender.blend(
        %Class{
          name: "left",
          parameters: %{
            "list" => [1, 2],
            "olist" => [1, 2],
            "map" => %{
              "a" => 1,
              "b" => %{
                "b" => "b"
              },
              "c" => %{
                "c" => "c"
              }
            }
          },
          valid?: true
        },
        %Class{
          name: "right",
          parameters: %{
            "list" => [3, 4],
            "~olist" => [3, 4],
            "map" => %{
              "a" => 1,
              "b" => %{
                "bb" => "bb"
              },
              "~c" => %{
                "cc" => "cc"
              },
              "d" => 4
            }
          },
          valid?: true
        }
      )

      assert result.parameters == %{
               "list" => [1, 2, 3, 4],
               "olist" => [3, 4],
               "map" => %{
                 "a" => 1,
                 "b" => %{
                   "b" => "b",
                   "bb" => "bb"
                 },
                 "c" => %{
                   "cc" => "cc"
                 },
                 "d" => 4
               }
             }
    end

    test "append right.applications to left.applications (empty)" do
      {:ok, result} = Blender.blend(
        %Class{name: "left", applications: [], valid?: true},
        %Class{name: "right", applications: [], valid?: true}
      )
      assert result.applications == []
    end

  end

  describe "correctly returns warnings" do
    test "deep merges parameters" do
      {:ok, result} = Blender.blend(
        %Class{
          name: "left",
          parameters: %{
            "a" => ["a list here"]
          },
          valid?: true
        },
        %Class{
          name: "right",
          parameters: %{
            "a" => "now a string"
          },
          valid?: true
        }
      )
      assert result.name == "right"
      assert result.parameters == %{
               "a" => "now a string"
             }

      assert result.messages == [
               %Message{severity: :warning, message: "overwrites list 'a' with scalar"}
             ]
    end
  end

end