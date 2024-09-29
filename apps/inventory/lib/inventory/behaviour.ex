defmodule MJ.Inventory.Behaviour do
  @moduledoc """
  MJ Inventory Interface.
  """
  alias MJ.Inventory.Error
  alias MJ.Inventory.Store.Behaviour, as: Storage
  alias MJ.Inventory.Store.Element

  @typedoc """
  The handle for the inventory.
  """
  @opaque t :: GenServer.name()

  @doc """
  Initialize the inventory.

  This method should prepare the inventory for later usage.

  * Check that the repo exists.
  * Fill up the caches (if any)
  """
  @callback init(inventory :: t()) :: {:ok, t()} | Error.t()

  @doc """
  List the elements of type `type` or `:all` of them.
  """
  @callback list(inventory :: t(), type :: :all | Element.type()) ::
              {:ok, list(Element.t())} | Error.t()

  @doc """
  Update/Put one element.
  """
  @callback get(inventory :: t(), element :: Element.t(), type :: :source) ::
              {:ok, String.t()} | Error.t()
  @callback get(inventory :: t(), element :: Element.t(), type :: :source_map) ::
              {:ok, map()} | Error.t()
  @callback get(inventory :: t(), element :: Element.t(), type :: :evaluated) ::
              {:ok, map()} | Error.t()

  @doc """
  Return the Storage behind the inventory.
  """
  @callback repo(inventory :: t()) :: {:ok, Storage.t()} | Error.t()
end
