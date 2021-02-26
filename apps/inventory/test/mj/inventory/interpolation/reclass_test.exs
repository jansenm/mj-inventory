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

defmodule MJ.Inventory.Interpolation.ReclassTest do
  use ExUnit.Case

  alias MJ.Inventory.Interpolation.Reclass

  # @moduletag :capture_log

  doctest Reclass

  test "substitution" do
    assert "Hello Michael" ==
             %{
               parameters: %{
                 "name" => "Michael",
                 "motd" => "Hello ${name}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "motd"])
  end

  test "multiple substitutions in one string" do
    assert "Hello Michael Jansen" ==
             %{
               parameters: %{
                 "name" => %{
                   "firstname" => "Michael",
                   "lastname" => "Jansen"
                 },
                 "motd" => "Hello ${name:firstname} ${name:lastname}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "motd"])
  end

  test "nested substitution in list" do
    assert ["Hello Michael Jansen"] ==
             %{
               parameters: %{
                 "name" => %{
                   "firstname" => "Michael",
                   "lastname" => "Jansen"
                 },
                 "motd" => ["Hello ${name:firstname} ${name:lastname}"]
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "motd"])
  end

  test "nested substitution in map" do
    assert "Hello Michael" ==
             %{
               parameters: %{
                 "name" => %{
                   "firstname" => "Michael"
                 },
                 "motd" => "Hello ${name:firstname}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "motd"])
  end

  test "deeply nested substitution in map" do
    assert ["Hello Michael Jansen"] ==
             %{
               parameters: %{
                 "a" => %{
                   "b" => %{
                     "c" => ["Hello ${name:firstname} ${name:lastname}"]
                   }
                 },
                 "name" => %{
                   "firstname" => "Michael",
                   "lastname" => "Jansen"
                 }
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "a", "b", "c"])
  end

  test "circular dependency is detected" do
    assert {
             :error,
             :circular_dependency,
             [
               "strings",
               "nested",
               "a",
               "${strings:nested:b}",
               "${strings:nested:a}"
             ]
           } ==
             %{
               parameters: %{
                 "strings" => %{
                   "nested" => %{
                     "a" => "${strings:nested:b}",
                     "b" => "${strings:nested:a}"
                   }

                 }
               }
             }
             |> Reclass.interpolate()
  end

  test "circular dependency is not falsely detected" do
    assert %{} = %{
               parameters: %{
                 "a" => %{
                   "b" => %{
                     "a" => %{
                       "b" => true
                     }
                   }
                 }
               }
             }
             |> Reclass.interpolate()
  end

  test "order does not matter" do
    assert "Hello c" ==
             %{
               parameters: %{
                 "a" => "${c}",
                 "b" => "Hello ${a}",
                 "c" => "c"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "b"])

    assert "Hello b" ==
             %{
               parameters: %{
                 "a" => "Hello ${c}",
                 "b" => "b",
                 "c" => "${b}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "a"])
  end

  test "full substitution preserves type" do
    assert [1, 2] ==
             %{
               parameters: %{
                 "a" => [1, 2],
                 "b" => "${a}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "b"])
  end

  test "full substitution does not ignore trailing/preceding whitespace" do
    assert <<1, 2, ?\s>> ==
             %{
               parameters: %{
                 "a" => [1, 2],
                 "b" => "${a} "
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "b"])

    assert <<?\s, 1, 2>> ==
             %{
               parameters: %{
                 "a" => [1, 2],
                 "b" => " ${a}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "b"])

    assert <<?\s, 1, 2, ?\s>> ==
             %{
               parameters: %{
                 "a" => [1, 2],
                 "b" => " ${a} "
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "b"])
  end

  test "substitution referencing missing value reports error" do
    assert {:error, :invalid_reference, ["b"], "${a}"} ==
             %{
               parameters: %{
                 "b" => "${a}"
               }
             }
             |> Reclass.interpolate()
  end

  test "compatibility with reclass: no recursive evaluation" do
    # In reclass the following is used to escape '$' when needed.
    assert "var=${catalina.base}" ==
             %{
               parameters: %{
                 "dollar" => "$",
                 "a" => "var=${dollar}{catalina.base}"
               }
             }
             |> Reclass.interpolate()
             |> get_in([:parameters, "a"])
  end
end
