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

defmodule MJ.Inventory.Registry do

  @moduledoc """
  A registry for class and nodes.
  """

  alias MJ.Inventory.Types.{Class, Node}

  @opaque t :: atom() | :ets.tid()

  @spec new() :: t()
  def new() do
    :ets.new(:registry, [])
  end

  @spec delete(t()) :: :ok
  def delete(registry) do
    :ets.delete(registry)
    :ok
  end

  @spec put(t(), %Class{} | %Node{}) :: :ok
  def put(registry, %Class{} = class) do
    :ets.insert(registry, {{:class, class.name}, class})
    :ok
  end

  def put(registry, %Node{} = node) do
    :ets.insert(registry, {{:node, node.name}, node})
  end

  @spec get(t(), {:class | :node, String.t()}) :: {:ok, %Class{} | %Node{}} | {:error, atom() | String.t()}
  def get(registry, {:class, _name} = obj) do
    case :ets.lookup(registry, obj) do
      [] ->
        {:error, :not_found}
      [obj] ->
        {:ok, elem(obj, 1)}
    end
  end

  def get(registry, {:node, _name} = obj) do
    case :ets.lookup(registry, obj) do
      [] ->
        {:error, :not_found}
      [obj] ->
        {:ok, elem(obj, 1)}
    end
  end

  @spec remove(t(), {:node | :class, String.t()}) :: :ok
  def remove(registry, {:node, _} = key) do
    :ets.delete(registry, key)
    :ok
  end

  def remove(registry, {:class, _} = key) do
    :ets.delete(registry, key)
    :ok
  end

  @spec remove_all(t()) :: :ok
  def remove_all(registry) do
    :ets.delete_all_objects(registry)
    :ok
  end

  @spec get_names(t(), :class | :node) :: list(String.t())
  def get_names(registry, :node) do
    :ets.match(registry, {{:node, :"$1"}, :_})
    |> List.flatten()
  end

  def get_names(registry, :class) do
    :ets.match(registry, {{:class, :"$1"}, :_})
    |> List.flatten()
  end

  @spec has_errors?(t()) :: boolean
  def has_errors?(registry) do
    :ets.foldl(
      fn {_name, obj}, acc -> acc or not obj.valid? end,
      false,
      registry
    )
  end

  @spec errors(t()) :: [String.t()]
  def errors(registry) do
    result = :ets.foldl(
      fn {name, obj}, acc ->
        case obj.errors do
          [] -> acc
          errors -> [{name, errors} | acc]
        end
      end,
      [],
      registry
    )
    List.flatten(result)
  end

end
