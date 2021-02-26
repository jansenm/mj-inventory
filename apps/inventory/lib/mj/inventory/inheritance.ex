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

defmodule MJ.Inventory.Inheritance do
  @moduledoc """
  Implement functions to support inheritance in classes/nodes.
  """
  alias MJ.Inventory.Registry
  alias MJ.Inventory.Types.{Class, Node}
  alias MJ.Inventory.Errors

  def _inheritance_path(%Class{} = class, inheritance_path, stack, registry) do
    if {:class, class.name} in stack do
      path = Enum.take(stack, Enum.find_index(stack, &(&1 == {:class, class.name})) + 1)
      raise Errors.CircularDependencyError, name: class.name, path: path
    end

    _inheritance_path(
      class.classes,
      [{:class, class.name} | inheritance_path],
      [{:class, class.name} | stack],
      registry
    )
  end

  def _inheritance_path([], inheritance_path, _stack, _registry) do
    inheritance_path
  end

  def _inheritance_path(classes, inheritance_path, stack, registry) do
    classes
    |> Enum.reverse()
    |> Enum.reduce(
         inheritance_path,
         fn cls, acc ->
           case Registry.get(registry, {:class, cls}) do
             {:ok, parent} ->
               _inheritance_path(parent, acc, stack, registry)
             {:error, :not_found} ->
               _inheritance_path(
                 %Class{
                   name: cls,
                   valid?: false,
                   errors: ["undefined class"]
                 },
                 acc,
                 stack,
                 registry
               )
           end
         end
       )
  end

  @spec inheritance_path(%Node{} | %Class{}, Registry.t()) :: list(String.t())
  def inheritance_path(%Node{} = node, registry) do
    _inheritance_path(node.classes, [{:node, node.name}], [], registry)
    |> Enum.uniq()
  end

  def inheritance_path(%Class{} = class, registry) do
    _inheritance_path(class.classes, [{:class, class.name}], [{:class, class.name}], registry)
    |> Enum.uniq()
  end


end
