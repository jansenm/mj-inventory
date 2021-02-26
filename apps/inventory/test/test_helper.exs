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

# Configure and Start ExUnit

defmodule TestHelper do
  alias MJ.Inventory.Registry
  alias MJ.Inventory
  alias MJ.Inventory.Types.{Node, Class}

  def register_inventory(definition, inventory) do
    define(definition)
    |> Enum.map(&(Inventory.put(inventory, &1)))
  end

  def register(definition, registry) do
    define(definition)
    |> Enum.map(&(Registry.put(registry, &1)))
  end

  def define_one(definition) do
    {:ok, documents} = MJ.Parser.Yaml.parse(definition)
    [document] = documents
    create(document)
  end

  def define(definition) do
    {:ok, documents} = MJ.Parser.Yaml.parse(definition)
    documents
    |> Enum.map(&(create(&1)))
  end

  defp create(%{"type" => "node", "name" => name} = map) when is_map(map) do
    Node.from_map(Map.delete(map, "type"), name, "__MAP__")
  end

  defp create(%{"type" => "class", "name" => name} = map) when is_map(map) do
    Class.from_map(Map.delete(map, "type"), name, "__MAP__")
  end

  defp create(map) when is_map(map) do
    raise RuntimeError, "not implemented"
  end

  def load_reclass_inventory(path) do
    IO.puts(path)
    {:ok, content} = File.read(Path.expand("#{path}/reclass.json"))
    {:ok, config} = Jason.decode(content)
    [reclass_config: config]
  end

  ExUnit.configure formatters: [JUnitFormatter, ExUnit.CLIFormatter]
  ExUnit.start(
    exclude: [
      reclass: true
    ]
  )

end
