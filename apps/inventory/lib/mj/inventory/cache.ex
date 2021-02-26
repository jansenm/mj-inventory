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

defmodule MJ.Inventory.Cache do

  @moduledoc """
  A cache module for classes and nodes.
  """

  alias MJ.Inventory.Types.{Class, Node}

  @opaque t :: atom() | :ets.tid()

  @spec new() :: t()
  def new() do
    :ets.new(:cache, [])
  end

  @spec delete(t()) :: :ok
  def delete(cache) do
    :ets.delete(cache)
    :ok
  end

  @spec put(t(), {:class | :node, String.t()}, {:ok, %Class{} | %Node{}}, list(atom())) :: :ok
  def put(cache, what, value, badges \\ []) do
    :ets.insert(cache, {what, value, badges})
    :ok
  end

  @spec has_errors?(t()) :: boolean
  def has_errors?(cache) do
    :ets.foldl(
      fn {_name, value, _badges}, acc ->
        case value do
          {:ok, obj} -> acc or not obj.valid?
        end
      end,
      false,
      cache
    )
  end

  def errors(cache) do
    result = :ets.foldl(
      fn {name, value, _}, acc ->
        case value do
          {:ok, obj} ->
            case obj.errors do
              [] -> acc
              errors -> [{name, errors} | acc]
            end
        end
      end,
      [],
      cache
    )
    List.flatten(result)
  end

  @spec get(t(), {:class | :node, String.t()}) :: {:ok, %Class{} | %Node{}} | nil
  def get(cache, {:class, _name} = obj) do
    case :ets.lookup(cache, obj) do
      [] ->
        nil
      [obj] ->
        obj
        |> elem(1)
    end
  end

  def get(cache, {:node, _name} = obj) do
    case :ets.lookup(cache, obj) do
      [] ->
        nil
      [obj] ->
        obj
        |> elem(1)
    end
  end

  def get(cache, {:class, _name} = obj, :badges) do
    case :ets.lookup(cache, obj) do
      [] ->
        nil
      [obj] ->
        obj
        |> elem(2)
    end
  end

  def get(cache, {:node, _name} = obj, :badges) do
    case :ets.lookup(cache, obj) do
      [] ->
        nil
      [obj] ->
        obj
        |> elem(2)
    end
  end

  @spec remove(t(), {:node | :class, String.t()}) :: :ok
  def remove(cache, {:node, _} = key) do
    :ets.delete(cache, key)
    :ok
  end

  def remove(cache, {:class, _} = key) do
    :ets.delete(cache, key)
    :ok
  end


  @spec remove_all(t()) :: :ok
  def remove_all(cache) do
    :ets.delete_all_objects(cache)
    :ok
  end


  @spec get_names(t(), :class | :node) :: list(String.t())
  def get_names(cache, :node) do
    :ets.match(cache, {{:node, :"$1"}, :_})
    |> List.flatten()
  end

  def get_names(cache, :class) do
    :ets.match(cache, {{:class, :"$1"}, :_})
    |> List.flatten()
  end

  def get_names_and_badges(cache, :node) do
    :ets.match(cache, {{:node, :"$1"}, :_, :"$2"})
  end

  def get_names_and_badges(cache, :class) do
    :ets.match(cache, {{:class, :"$1"}, :_, :"$2"})
  end

end
