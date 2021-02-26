# SPDX-FileCopyrightText: 2021 Michael Jansen <info@michael-jansen.biz>
# SPDX-License-Identifier: CC0-1.0
defmodule Inventory.MixProject do
  use Mix.Project

  def project do
    [
      app: :inventory,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # For some reason this configuration does not work from the umbrella mix.exs
      test_coverage: [
        tool: :covertool
      ],
      # Command line tool to generate the inventory
      escript: [
        main_module: MJ.Inventory.CLI
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {MJ.OTP.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:yamerl, "~> 0.8"},
      {:libgraph, "~>0.13.3"},
      {:phoenix_pubsub, "~>2.0.0"},
      {:jason, "~> 1.0"}
    ]
  end
end
