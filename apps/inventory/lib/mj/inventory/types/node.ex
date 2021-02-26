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

defmodule MJ.Inventory.Types.Node do
  @moduledoc """
  A node describes a concrete object in the inventory.

  It could be a host if the inventory is used for a tool like ansible or puppet. A
  jenkins job if you use the inventory do configure your Job-DSL.

  Or it could mean a lot of different things in your inventory if you utilize classes to mark the
  concrete type. For example it could describe both hosts and user accounts on those hosts.
  """

  use MJ.Inventory.Types.Common

end
