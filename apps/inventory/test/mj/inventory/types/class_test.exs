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

defmodule ClassTest do
  use ExUnit.Case

  alias MJ.Inventory.Types.Class

  @moduletag :capture_log

  doctest Node

  test "module exists" do
    assert is_list(Node.module_info())
  end

  # Node and Class are identical so far. Make it easy to copy test file
  Module.put_attribute(__MODULE__, :cls, Class)
  Module.put_attribute(__MODULE__, :clsname, "Class")

  describe to_string(@clsname) do
    setup do
      [
        entity: %@cls{
          name: 'myclass'
        }
      ]
    end

    test "can be initialized", context do
      assert context.entity != nil
    end

    test "sets the name", context do
      assert context.entity.name == 'myclass'
    end

    test "is valid by default", context do
      assert context.entity.valid?
    end

    test "has no errors", context do
      assert context.entity.errors == []
    end

    test "returns nil for source_ref", context do
      assert context.entity.source_ref == nil
    end


    test "returns a empty map for parameters", context do
      assert context.entity.parameters == %{}
    end

    test "returns a empty list for classes", context do
      assert context.entity.classes == []
    end

    test "returns a empty list for applications", context do
      assert context.entity.applications == []
    end

  end

  describe @clsname <> " can be initialized" do

    test "from a map" do
      entity = @cls.from_map(
        %{
          "classes" => ["BaseA", "BaseB"],
          "applications" => ["vim"],
          "parameters" => %{
            "a key" => "a value"
          }
        },
        "test2",
        "",
        "__STRING__"
      )
      assert entity.name == "test2"
      assert entity.valid?
      assert entity.errors == []
      assert entity.classes == ["BaseA", "BaseB"]
      assert entity.parameters == %{"a key" => "a value"}
      assert entity.source_ref == "__STRING__"
      assert entity.applications == ["vim"]
    end

    test "from a invalid map" do
      entity = @cls.from_map(
        %{
          "classes" => ["BaseA", "BaseB"],
          "thisshouldntbehere" => false,
          "parameters" => %{
            "a key" => "a value"
          }
        },
        "test3",
        "",
        "__STRING__"
      )
      assert entity.name == "test3"
      refute entity.valid?
      assert entity.errors == ["parsing error:unknown section »thisshouldntbehere«"]
      assert entity.applications == []
      assert entity.classes == []
      assert entity.parameters == nil
      assert entity.source_ref == "__STRING__"
    end
  end

end

