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

defmodule MJ.Inventory.Interpolation.Reclass do
  @moduledoc false

  def interpolate(%{parameters: parameters} = object) do
    try do
      result = do_interpolate(parameters, object, [])
      %{object | parameters: result}
    catch
      {:circular_dependency, stack} -> {:error, :circular_dependency, Enum.reverse(stack)}
      {:invalid_reference, stack, what} -> {:error, :invalid_reference, stack, what}
    end
  end

  defp do_interpolate(map, object, stack) when is_map(map) do
    Enum.map(
      map,
      fn {name, value} ->
        {name, do_interpolate(value, object, [name | stack])}
      end
    )
    |> Enum.into(%{})
  end

  defp do_interpolate(list, object, stack) when is_list(list) do
    Enum.map(
      Enum.with_index(list),
      fn {value, index} -> do_interpolate(value, object, [index | stack]) end
    )
  end

  defp do_interpolate(string, object, stack) when is_binary(string) do
    Regex.scan(~r/\$\{(.*)\}/U, string, capture: :all, return: :index)
    # We substitute from back to front to not invalidate the indizes we get.
    |> Enum.reverse()
    |> Enum.reduce(string, fn capture, acc -> do_interpolate(capture, acc, object, stack) end)
  end

  defp do_interpolate(others, _object, _stack) do
    others
  end

  defp do_interpolate(capture, string, object, stack) when is_binary(string) do
    # The substitution string with braces
    index = Enum.at(capture, 0)
    what = String.slice(string, elem(index, 0), elem(index, 1))

    # The substitution string without braces
    index = Enum.at(capture, 1)
    path = String.slice(string, elem(index, 0), elem(index, 1))

    # Now we know what we are supposed to replace check if we are in a circular dependency loop
    if Enum.member?(stack, what) do
      throw {:circular_dependency, stack}
    end

    result = try do
      with = do_interpolate_one(path, object, [what | stack])
      if what == string do
        # We do not substitute the complete string. Just copy over with ... preserving its type
        with
      else
        # We do not substitute the complete string. Insert the stringified with at the placeholder.
        String.replace(string, what, to_string(with))
      end
    rescue
      KeyError ->
        throw {:invalid_reference, stack, what}
    end

    result
  end

  defp do_interpolate_one(path, object, stack) do
    keys = path
           |> String.split(":")
           |> Enum.map(&String.trim(&1))
    string = get_in(
      object.parameters,
      Enum.map(keys, fn key -> Access.key!(key) end)
    )
    do_interpolate(string, object, stack)
  end

end
