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

defmodule MJ.Inventory.Errors do
  @moduledoc """
  The errors used in this module.
  """

  defmodule CircularDependencyError do
    defexception [:message, :path, :name]
    @impl true
    def exception(params) do
      name = Keyword.get(params, :name)
      path = Keyword.get(params, :path) |> Enum.map(fn {:class, cls} -> cls end) |> Enum.join(" <- ")
      %CircularDependencyError{
        message: "Circular dependency detected for class #{name}: #{name} <- #{path}",
        path: path,
        name: name
      }
    end
  end
end
