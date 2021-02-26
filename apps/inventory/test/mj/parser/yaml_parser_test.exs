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

defmodule MJ.Parser.YamlTest do
  use ExUnit.Case

  alias MJ.Parser.Yaml, as: YamlParser

  @moduletag :capture_log

  doctest YamlParser

  test "module exists" do
    assert is_list(YamlParser.module_info())
  end

  describe "handles valid yaml" do

    test "empty string" do
      assert YamlParser.parse("") == {:ok, [nil]}
    end

    test "valid empty yaml stream" do
      assert YamlParser.parse("---") == {:ok, [nil]}
    end

    test "valid empty multi document yaml stream" do
      assert YamlParser.parse(
               """
               ---
               ---
               """
             ) == {:ok, [nil, nil]}
    end

    test "valid multi document yaml stream" do
      assert YamlParser.parse(
               """
               ---
               parameters:
               ---
               classes:
               """
             ) == {:ok, [%{"parameters" => nil}, %{"classes" => nil}]}
    end

    test "valid yaml top level list" do
      assert YamlParser.parse(
               """
               ---
               - 1
               - 2
               """
             ) == {:ok, [[1, 2]]}
    end

  end # describe

  test "transforms all yaml datatypes" do
    # We are not unit testing yamerl here. We test our transform functions.
    assert YamlParser.parse(
             """
             "null": null
             "bool": true
             bool2: yes
             integer: 42
             negative: !!float -1
             zero: 0.
             """
           ) == {
             :ok,
             [
               %{
                 "null" => nil,
                 "bool" => true,
                 # :TODO: report this bug
                 "bool2" => "yes",
                 "integer" => 42,
                 "negative" => -1.0,
                 "zero" => 0.0
               }
             ]
           }
  end
end
