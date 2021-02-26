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

defmodule MJ.OTP.Application do
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, []) do
    children = [
      {Phoenix.PubSub, name: MJ.Inventory.PubSub},
    ]
    {:ok, _child} = Supervisor.start_link(children, strategy: :one_for_one)
  end

  @impl true
  def stop(_state) do
    #Logger.debug("* stopping application")
  end
end