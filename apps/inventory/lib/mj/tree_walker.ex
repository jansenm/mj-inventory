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

defmodule MJ.TreeWalker do
  @moduledoc false

  def walk(dir, filter) do
    Stream.resource(
      fn -> [%{files: [], directories: [dir], filter: filter}] end,
      fn stack ->
        get_next(stack)
      end,
      fn _ -> true end
    )
  end

  def get_next([] = stack) when is_list(stack) do
    {:halt, []}
  end

  def get_next(stack) do
    [curr | rest] = stack
    case handle_context(curr) do
      {:halt, _} -> get_next(rest)
      {files, nil} -> {files, rest}
      [curr, deep] -> get_next([deep, curr] ++ rest)
    end
  end

  def handle_context(%{files: [], directories: []} = context) do
    {:halt, context}
  end

  def handle_context(%{directories: []} = context) do
    {context.files, nil}
  end

  def handle_context(%{} = context) do
    [dir | rest] = context.directories
    deep = with {:ok, elems} <- File.ls(dir) do
      elems
      |> Enum.reduce(
           %{files: [], directories: [], filter: context.filter},
           fn elem, acc ->
             fullpath = Path.join(dir, elem)
             case File.dir? fullpath do
               true -> %{acc | directories: [fullpath | acc.directories]}
               false -> %{acc | files: [fullpath | acc.files]}
             end
           end
         )
    end

    # filter out the unwanted files
    deep = %{deep | files: Enum.filter(deep.files, context.filter)}

    [
      %{context | directories: rest},
      deep
    ]
  end

end
