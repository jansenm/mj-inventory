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

defmodule MJ.Inventory.Repository do
  @moduledoc """
  This modules defines the behaviour required to implement a repository.

  A repository is used to store the configuration for a inventory. It could be backed by the file system or a database.
  """
  alias MJ.Repository.File, as: FileStore
  alias MJ.Inventory

  defmacro __using__(_opts) do
    quote do
      @behaviour MJ.Inventory.Repository
    end
  end


  def load(inventory, opts) do
    load(inventory, Keyword.get(opts, :type, :missing), opts)
  end

  def load(_inventory, :missing, _opts) do
    raise ArgumentError, message: "repository type not configured"
  end

  def load(inventory, :empty, _opts) do
    MJ.Inventory.unload(inventory)
    inventory
  end

  def load(inventory, :file, opts) do
    path = Keyword.get(opts, :path)
    if path == nil do
      raise ArgumentError, message: "path not provided"
    end

    # First clean out any old content
    MJ.Inventory.unload(inventory)

    FileStore.load(path: Path.expand(path))
    |> Enum.each(fn obj -> Inventory.put(inventory, obj) end)

    inventory
  end

  def load(_inventory, type, _opts) do
    raise ArgumentError, message: "repository type #{type} not implemented"
  end

end
