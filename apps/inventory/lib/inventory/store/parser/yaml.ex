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

defmodule MJ.Inventory.Store.Parser.Yaml do
  @moduledoc """
  Parse configuration from yaml files.
  """

  use MJ.Inventory.Store.Parser
  use MJ.Inventory.ErrorContext

  require Logger

  @doc """
  See `c:MJ.Inventory.Store.Parser.parse/1`
  """
  @impl true
  def parse(definition) do
    try do
      :yamerl_constr.string(definition, [{:detailed_constr, true}])
    catch
      {:yamerl_exception, [{:yamerl_parsing_error, :error, message, line, char, _, _, _}]} ->
        ErrorContext.create(
          :parsing_error,
          "Parsing error at %{line}:%{char}:%{message}",
          %{message: message, char: char, line: line}
        )

      error ->
        # credo:disable-for-next-line Credo.Check.Warning.IoInspect
        Logger.critical("Handling #{inspect(error)} not implemented yet")

        ErrorContext.create(
          :yamerl_error,
          "Unhandled yamerl_error %{error_string}",
          %{error: error, error_string: inspect(error)}
        )
    else
      [] ->
        [nil]

      documents ->
        documents
        |> Enum.map(&transform(&1))
        |> Enum.into([])
    end
  end

  @doc """
  See `c:MJ.Inventory.Store.Parser.parse_one/1`
  """
  @impl true
  def parse_one(definition) do
    case parse(definition) do
      [one] ->
        one

      [_ | _rest] ->
        ErrorContext.create(
          :multi_document,
          "The definition is a yaml multi-document but only one definition expected"
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp transform({:yamerl_map, :yamerl_node_map, _tag, _loc, list}) do
    list
    |> Enum.map(fn {key, value} -> {transform(key), transform(value)} end)
    |> Enum.into(%{})
  end

  defp transform({:yamerl_str, :yamerl_node_str, _tag, _loc, string}) do
    to_string(string)
  end

  defp transform({:yamerl_int, :yamerl_node_int, _tag, _loc, value}) do
    value
  end

  defp transform({:yamerl_float, :yamerl_node_float, _tag, _loc, value}) do
    value
  end

  defp transform({:yamerl_bool, :yamerl_node_bool, _tag, _loc, value}) when is_boolean(value) do
    value
  end

  defp transform({:yamerl_seq, :yamerl_node_seq, _tag, _loc, list, _len}) do
    list
    |> Enum.map(fn value -> transform(value) end)
  end

  defp transform({:yamerl_null, :yamerl_node_null, _tag, _loc}) do
    nil
  end

  defp transform({:yamerl_doc, map}) do
    transform(map)
  end

  defp transform(val) do
    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    Logger.error("yaml:unknown token #{inspect(val)} encountered.")
    raise RuntimeError, "fixme"
  end
end
