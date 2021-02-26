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

# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :inventory_web,
  namespace: MJ.InventoryWeb,
  generators: [context_app: false]

# Configures the endpoint
config :inventory_web, MJ.InventoryWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "kXeU4Cs4HZyP9OD4QqJbzOWn4mo3pP4qtkCUpEXqWkvNyerupYcw5w0LC80aRhHE",
  render_errors: [view: MJ.InventoryWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MJ.Inventory.PubSub,
  live_view: [signing_salt: "8Hc4Y/9w"]

# By default, the umbrella project as well as each child
# application will require this configuration file, as
# configuration and dependencies are shared in an umbrella
# project. While one could configure all applications here,
# we prefer to keep the configuration of each individual
# child application in their own app, but all other
# dependencies, regardless if they belong to one or multiple
# apps, should be configured in the umbrella to avoid confusion.
#for config <- "../apps/*/config/config.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
#  import_config config
#end

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :inventory_web,
       :repository,
       [type: :file, path: System.get_env("REPOSITORY", "apps/inventory/test/data/example")]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
