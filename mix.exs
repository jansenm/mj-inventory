defmodule Testing01.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      name: "Inventory",
      deps: deps(),
      dialyzer: [
        flags: ["-Wunmatched_returns", :error_handling, :underspecs]
      ],
      # test_coverage: [tool: :coverage],
      docs: [
        # The main page in the docs
        main: "readme",
        # logo: "path/to/logo.png",
        extras: ["README.md"],
        language: "en",
        output: "_build/doc",
        markdown_processor: ExDoc.Markdown.Earmark,
        markdown_processor_options: [gfm: true]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      # test dependencies
      #  {:covertool, "~> 2.0.3", only: [:test]},
      {:junit_formatter, "~> 3.1", only: [:test]},

      # Development dependencies
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.23", only: :dev, runtime: false},
      {:earmark, "~> 1.4.13", only: :dev, runtime: false}
    ]
  end
end
