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

defmodule MJ.Inventory.Blender do
  @moduledoc """
  A blender is used to blend to inventory objects into one.

  It merges the configuration of a node and a class. The parts
  - applications
  - parameters
  are merged. The classes are dropped.

  A blender should return errors if it encounters invalid object as its parameters
  """

  alias MJ.Inventory.Types.{Class, Node}
  alias MJ.Inventory.Blender.Merge

  @type t :: %Node{} | %Class{}

  @spec blend(t(), t()) :: {:ok, t()} | {:error, atom(), t()}
  def blend(_, %{name: _, valid?: false} = right) do
    {
      :ok,
      %{
        right |
        applications: nil,
        parameters: nil,
        valid?: false,
        errors: right.errors
      }
    }
  end

  def blend(%{name: _, valid?: false} = left, right) do
    {
      :ok,
      %{
        right |
        applications: nil,
        parameters: nil,
        valid?: false,
        errors: ["Base class #{left.name} is invalid" | right.errors]
      }
    }
  end

  def blend(%Node{} = left, _) do
    {:error, :left_is_node, left} end

  def blend(%Class{} = left, %Node{} = right) do
    do_blend(left, right, %Node{name: right.name}) end

  def blend(%Class{} = left, %Class{} = right) do
    do_blend(left, right, %Class{name: right.name}) end

  @spec do_blend(t(), t(), t()) :: {:ok, t()}
  defp do_blend(left, right, result) do
    {
      :ok,
      %{
        result |
        classes: right.classes,
        applications: left.applications ++ right.applications,
        parameters: Merge.deep_merge(left.parameters, right.parameters)
      }
    }
  end

  defmodule Merge do

    @moduledoc """
    Helper module that implements the merging of maps
    """

    def resolve(key, left, right) when is_list(left) and is_list(right)  do
      {key, left ++ right}
    end

    def resolve(key, left, right) when is_map(left) and is_map(right)  do
      {key, deep_merge(left, right)}
    end

    def resolve(key, _left, right) do
      {key, right}
    end

    def match("~" <> key, _map, value) do
      {key, value}
    end

    def match(key, map, value) do
      resolve(key, map[key], value)
    end

    def deep_merge(%{} = left, %{} = right) do
      Enum.map(
        right,
        fn {key, value} ->
          match(key, left, value)
        end
      )
      |> Enum.into(left)
    end

    def deep_merge(%{} = _left, right) when is_binary(right) do
      # TODO this is a error on certain levels
      right
    end
  end
end
