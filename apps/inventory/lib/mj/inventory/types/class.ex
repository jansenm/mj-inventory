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

defmodule MJ.Inventory.Types.Class do
  @moduledoc """
  A class describes a abstract concept in your inventory.

  You define those abstract concepts to be able to easily apply them to your nodes.

  In a ansible or puppet inventory you could use classes to describe
    - server instances you want to setup on the hosts (eg. apache web server, postgres sql server).
    - software packages you want to install (eg. c++ development tools)
    - concepts like monitoring you want to apply to the server.
    - or just as a mixin to configure the operating system to install on the machine.
    - or additional installation repositories to enable on the hosts.

  Its your call how to utilize classes.
  """

  use MJ.Inventory.Types.Common

end
