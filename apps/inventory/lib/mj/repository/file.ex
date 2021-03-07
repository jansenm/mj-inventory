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

defmodule MJ.Repository.File do
  @moduledoc """
  A file store loads classes and nodes from filesystem
  """

  require Logger

  import MJ.TreeWalker
  alias MJ.Inventory.Types.{Class, Node, Message}

  @type opts :: keyword()


  @callback valid?(opts) :: boolean()
  def valid?(opts) do
    path = Keyword.get(opts, :path)
    File.dir?(path) and File.dir?(Path.join(path, 'classes')) and File.dir?(Path.join(path, 'nodes'))
  end

  @spec load(opts) :: [%Class{} | %Node{}]
  def load (opts) do
    unless valid?(opts) do
      raise MJ.Error, message: "The specified options do not point to a valid store"
    end

    path = Keyword.get(opts, :path)
    Logger.metadata([store: path])
    try do
      load_classes(Path.join(path, 'classes')) ++
      load_nodes(Path.join(path, 'nodes'))
    after
      Logger.metadata([store: nil])
    end
  end

  defp load_entities(root, factory) do
    walk(
      root,
      fn path ->
        Path.extname(path) in [".yaml", ".yml", ".toml"]
      end
    )
    |> Enum.map(
         fn path ->
           factory.(
                   root,
                   String.replace_prefix(path, "#{root}/", "")
                   )
         end
       )
  end

  @spec load_classes(String.t()) :: [%Class{}]
  defp load_classes(root) do
    load_entities(root, &load_class/2)
  end

  @spec load_nodes(String.t()) :: [%Node{}]
  defp load_nodes(root) do
    load_entities(root, &load_node/2)
  end

  @spec load_entity(String.t(), String.t(), module()) :: Class.t() | Node.t()
  defp load_entity(path, name, entity) do
    with {:ok, definition} <- File.read(path),
         {:ok, documents} <- MJ.Inventory.Parser.parse(definition, type_from_path(path)) do
      case documents do
        [] -> entity.from_map(%{}, name, definition, {nil, path})
        [document] -> entity.from_map(document, name, definition, {nil, path})
        [_ | _] -> %{entity.from_map(%{}, name, definition, {nil, path}) | valid?: false, messages: [Message.error("error:file contains yaml stream")]}
      end
    else
      # TODO: make sure definition is forwarded here if the file could be read.
      {:error, reason} -> %{entity.from_map(%{}, name, "", {nil, path}) | valid?: false, parameters: nil, messages: [Message.error(reason)]}
    end
  end

  @spec load_class(String.t(), String.t()) :: Class.t()
  def load_class(root, path) do
    load_entity(Path.join([root, path]), name_from_path(path), MJ.Inventory.Types.Class)
  end

  @spec load_node(String.t(), String.t()) :: Node.t()
  defp load_node(root, path) do
    load_entity(Path.join([root, path]), name_from_path(Path.basename(path)), MJ.Inventory.Types.Node)
  end

  @spec name_from_path(String.t()) :: String.t()
  defp name_from_path(path) do
    path
    |> Path.rootname()
    |> String.replace("/", ".")
  end

  @spec type_from_path(String.t()) :: :ignore | :toml | :yaml
  defp type_from_path(path) do
    path
    |> Path.extname()
    |> case do
         ".yaml" -> :yaml
         ".yml" -> :yaml
         ".toml" -> :toml
         _ -> :ignore
       end
  end

end
