defmodule MJ.Inventory.Store.Parser do
  @moduledoc """
  A parser parses a string into a elixir map.

  The inventory should support different file types (eg. yaml, toml or json) that
  can be used to define classes or nodes. To support the filetype you have to implement
  the Parser behaviour for the file type.
  """

  alias MJ.Inventory.Error

  @typedoc """
  The format of the definition file.
  """
  @type format :: :unknown | :yaml

  # :TODO: the behaviour should probably bee a submodule

  @doc """
  Returns the definition parsed from the file

  Return a list of configuration or errors encountered when parsing the file.

  The method makes it possible to support describing several nodes/classes in one file if supported by
  the file format (eg. yaml stream).

  The parser should not validate the top level keys. This will be done by the caller.
  """
  @callback parse(definition :: String.t()) :: list(map()) | Error.context_t()

  @doc """
  Parse exactly one element out of `definition`.

  This function has to ensure the string *is not a* YAML multi-document with several definitions.
  """
  @callback parse_one(definition :: String.t()) :: map() | Error.context_t()

  defmacro __using__(_opts) do
    quote do
      @behaviour MJ.Inventory.Store.Parser
    end
  end

  @doc """
  Parse one element out of `definition`.
  """
  @spec parse_one(String.t(), :yaml) :: map() | Error.context_t()
  def parse_one(definition, :yaml) do
    MJ.Inventory.Store.Parser.Yaml.parse_one(definition)
  end

  @doc """
  Parse all elements out of `definition`.
  """
  @spec parse(String.t(), :yaml) :: list(map()) | Error.context_t()
  def parse(definition, :yaml) do
    MJ.Inventory.Store.Parser.Yaml.parse(definition)
  end
end
