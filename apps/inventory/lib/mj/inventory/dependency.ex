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

defmodule MJ.Inventory.Dependency do
  @moduledoc false

  @opaque t :: Graph.t()

  @type class :: {:class, term()}
  @type class_or_node :: {:class | :node, term()}

  @spec new() :: t()
  def new() do
    Graph.new()
  end

  @spec add(t(), class(), class_or_node()) :: t()
  def add(deps, from, to) do
    Graph.add_edge(deps, from, to)
  end

  @spec topsort(t()) :: [class_or_node()]
  def topsort(deps) do
    Graph.topsort(deps)
  end

  @spec subgraph(t(), [class_or_node()]) :: t()
  def subgraph(deps, elems) do
    Graph.subgraph(deps, elems)
  end

end
