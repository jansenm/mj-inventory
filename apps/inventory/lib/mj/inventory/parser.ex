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

defmodule MJ.Inventory.Parser do
  @moduledoc """
  A parser parses a string into a elixir map.

  The inventory should support different file types (eg. yaml, toml or json) that
  can be used to define classes or nodes. To support the filetype you have to implement
  the Parser behaviour for the file type.
  """


  @doc """
  Returns the definition parsed from the file

  Return a list of configuration or errors encountered when parsing the file.

  The method makes it possible to support describing several nodes/classes in one file if supported by
  the file format (eg. yaml stream).

  The parser should not validate the top level keys. This will be done by the caller.
  """
  @callback parse(String.t()) :: {:ok, list(map())} | {:error, String.t()}


  defmacro __using__(_opts) do
    quote do
      @behaviour MJ.Inventory.Parser
    end
  end

  @spec parse(String.t(), :yaml) :: {:error, String.t()} | {:ok, [map()]}
  def parse(definition, :yaml) do
    MJ.Parser.Yaml.parse(definition)
  end

end
