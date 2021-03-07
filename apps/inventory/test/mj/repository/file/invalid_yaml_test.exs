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

defmodule MJ.Repository.File.InvalidYamlTest do
  use ExUnit.Case

  alias MJ.Repository.File, as: FileStore
  alias MJ.Inventory.Types.{Node, Message}

  @moduletag :capture_log


  test "gives error on invalid root directory" do
    assert_raise MJ.Error, fn ->
      FileStore.load(path: Path.expand("./test/data/missing"))
    end
  end


  setup_all do
    entities = FileStore.load(path: Path.expand("./test/data/invalid_yaml"))
    {:ok, entities: entities}
  end

  describe "inventory with invalid files" do

    test "loads all nodes", %{entities: entities} do
      assert Enum.count(entities) == 3
    end

    test "successfully loads valid yaml files", %{entities: entities} do
      valid_node = Enum.find(
        entities,
        fn
          %Node{name: "valid"} -> true
          _ -> false
        end
      )

      path = Path.join([Path.expand("./test/data/invalid_yaml"), "nodes/valid.yaml"])
      assert %Node{
               valid?: true,
               messages: [],
               source_ref: {nil, ^path},
               parameters: %{
                 "motd" => "Hello"
               }
             } = valid_node
    end

    test "successfully loads valid yaml files with extra sections", %{entities: entities} do
      invalid_node = Enum.find(
        entities,
        fn
          %Node{name: "valid_yaml_invalid_key"} -> true
          _ -> false
        end
      )

      path = Path.join([Path.expand("./test/data/invalid_yaml"), "nodes/valid_yaml_invalid_key.yaml"])
      assert %Node{
               valid?: false,
               messages: [%Message{severity: :error, message: "parsing error:unknown section »invalidkey«"}],
               source_ref: {nil, ^path},
               parameters: %{}
             } = invalid_node
    end

    test "successfully loads invalid yaml files", %{entities: entities} do
      valid_node = Enum.find(
        entities,
        fn
          %Node{name: "invalid_yaml"} -> true
          _ -> false
        end
      )

      path = Path.join([Path.expand("./test/data/invalid_yaml"), "nodes/invalid_yaml.yaml"])
      assert %Node{
               valid?: false,
               messages: [
                 %Message{
                   severity: :error,
                   message: "parsing error:Unexpected \"yamerl_collection_start\" token following a \"yamerl_scalar\" token at [4:3]"
                 }
               ],
               source_ref: {nil, ^path},
               parameters: nil
             } = valid_node
    end
  end
end
