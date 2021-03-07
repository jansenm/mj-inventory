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
  alias MJ.Inventory.Types.Message

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
        messages: right.messages
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
        messages: [Message.error("inheritance error:base class #{left.name} is invalid") | right.messages]
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
    {merged, warnings} = Merge.deep_merge(left.parameters, right.parameters, "")
    {
      :ok,
      %{
        result |
        classes: right.classes,
        applications: left.applications ++ right.applications,
        parameters: merged,
        messages: warnings ++ right.messages
      }
    }
  end

  defmodule Merge do

    @moduledoc """
    Helper module that implements the merging of maps
    """

    ### HELPER
    def context("", key) do
      key end
    def context(name, key) do
      "'#{name}'.#{key}" end

    ### MERGE NAMES IN MAPS

    # If the name starts with `~` and the values is a map or list then don't merge but overwrite
    def merge_name("~" <> key, map, value, _name) when is_map(map) and (is_list(value) or is_map(value)) do
      {key, {value, []}}
    end

    # For all other names merge the values.
    def merge_name(key, map, value, name) when is_map(map) do
      {key, deep_merge(map[key], value, context(name, key))}
    end

    ### DEEP MERGE VALUES
    def deep_merge(left, right, name \\ "")

    # TWO MAPS.
    def deep_merge(left, right, name) when is_map(left) and is_list(right) do
      {right, [Message.warning("overwrites map '#{name}' with list")]}
    end

    def deep_merge(left, right, name) when is_map(left) and not is_map(right) do
      {right, [Message.warning("overwrites map '#{name}' with scalar")]}
    end

    def deep_merge(left, right, name) when is_map(left) and is_map(right) do
      right
      |> Enum.map(
           fn {key, value} ->
             merge_name(key, left, value, name)
           end
         )
      |> Enum.reduce(
           {left, []},
           fn {key, {merged, msg}}, {left, messages} ->
             case msg do
               [] -> {Map.put(left, key, merged), messages}
               msg -> {Map.put(left, key, merged), messages ++ msg}
             end
           end
         )
    end

    # TWO LISTS
    def deep_merge(left, right, name) when is_list(left) and is_map(right) do
      {right, [Message.warning("overwrites list '#{name}' with map")]}
    end

    def deep_merge(left, right, name) when is_list(left) and not is_list(right) do
      {right, [Message.warning("overwrites list '#{name}' with scalar")]}
    end

    def deep_merge(left, right, _name) when is_list(left) and is_list(right)  do
      {left ++ right, []}
    end

    # SCALARS
    def deep_merge(left, right, name) when left != nil and is_map(right) do
      {right, [Message.warning("overwrites scalar '#{name}' with map")]}
    end

    def deep_merge(left, right, name) when left != nil and is_list(right) do
      {right, [Message.warning("overwrites scalar '#{name}' with list")]}
    end

    # For everything else right overwrites left
    def deep_merge(_left, right, _name) do
      {right, []}
    end

  end
end
