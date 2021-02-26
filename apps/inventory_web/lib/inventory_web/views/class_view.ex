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

defmodule MJ.InventoryWeb.ClassView do
  @moduledoc false

  use MJ.InventoryWeb, :view

  def parameters({:ok, parameters}) do
    # ~e[<div class="content"><%= render_parameters(parameters) %></div>]
    {:ok, string} = Jason.encode(parameters, pretty: true)
    string
  end

  def parameters(parameters) do
    # ~e[<div class="content"><%= render_parameters(parameters) %></div>]
    {:ok, string} = Jason.encode(parameters, pretty: true)
    string
  end

  def render_parameters(parameters) when parameters == %{} do
    ~e"{}"
  end

  def render_parameters(parameters) when is_map(parameters) do
    ~e"<dl>
    <%= for {k, v} <- parameters do %>
    <dt><%= k %>:</dt>
    <dd><%= render_parameters(v) %></dd>
    <% end %>
    </dl>"
  end

  def render_parameters(parameters) when is_list(parameters) do
    ~e"<ul>
    <%= for v <- parameters do %>
    <li><%= render_parameters(v) %></li>
    <% end %>
    </ul>"
  end

  def render_parameters(nil) do
    "~"
  end

  def render_parameters(parameters) when is_binary(parameters) do
    ~e[<pre><%= parameters %></pre>]
  end

  def render_parameters(parameters) do
    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    inspect(parameters)
  end

end
