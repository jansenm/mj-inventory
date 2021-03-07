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

defmodule MJ.Inventory.Types.Common do
  @moduledoc """
  Shared code between Nodes and Classes
  """

  alias MJ.Inventory.Types.Message

  defmacro __using__(_opts) do
    quote do
      import MJ.Inventory.Types.Common

      @enforce_keys [:name]
      defstruct [
        :name,
        applications: [],
        parameters: %{},
        environment: "",
        classes: [],
        valid?: true,
        messages: [],
        source: nil,
        source_ref: nil
      ]

      @type repository :: {pid(), Keyword.t()}

      @type t :: %__MODULE__{
                   name: String.t(),
                   applications: list(),
                   parameters: map() | nil,
                   classes: list(),
                   environment: String.t(),
                   # error handling
                   valid?: boolean(),
                   messages: list(Message.t()),
                   # source reference.
                   source: String.t(),
                   source_ref: repository() | nil,
                 }

      @spec from_map(map() | nil, String.t(), repository() | nil) :: t()

      def from_map(map, name, source, source_ref \\ nil)

      def from_map(nil, name, source, source_ref) do
        from_map(%{}, name, source, source_ref)
      end

      def from_map(map, name, source, source_ref) when is_map(map) do
        Enum.reduce_while(
          map,
          %__MODULE__{
            name: name,
            source: source,
            source_ref: source_ref
          },
          fn
            {"name", value}, acc -> {:cont, %{acc | name: value}}
            {"applications", nil}, acc -> {:cont, %{acc | applications: []}}
            {"applications", value}, acc when is_list(value) -> {:cont, %{acc | applications: value}}
            {"applications", value}, acc -> {:cont, %{acc | applications: []}}
                                            {
                                              :cont,
                                              %__MODULE__{
                                                name: name,
                                                source_ref: source_ref,
                                                valid?: false,
                                                messages: [Message.error("parsing error:applications is not a list") | acc.messages]
                                              }
                                            }
            {"classes", nil}, acc -> {:cont, %{acc | classes: []}}
            {"classes", value}, acc -> {:cont, %{acc | classes: value}}
            {"environment", value}, acc -> {:cont, %{acc | environment: value}}
            {"parameters", nil}, acc -> {:cont, %{acc | parameters: %{}}}
            {"parameters", value}, acc -> {:cont, %{acc | parameters: value}}
            {key, value}, acc ->
              {
                :cont,
                %__MODULE__{
                  name: name,
                  source_ref: source_ref,
                  valid?: false,
                  parameters: nil,
                  messages: [Message.error("parsing error:unknown section »#{key}«") | acc.messages]
                }
              }
          end
        )
      end
    end
  end

end
