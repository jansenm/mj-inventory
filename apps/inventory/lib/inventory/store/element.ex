defmodule MJ.Inventory.Store.Element do
  @moduledoc """
  One element of a inventory.
  """

  @enforce_keys [:id, :store_handle]
  defstruct [:id, :store_handle]

  @typedoc """
  The type of the element.

  ## `:class`

  A class is an abstract concept. You can then apply those abstract concepts to your nodes by
  inheritance.

  Synonyms are

    * Role
    * Category
    * Marker
    * Trait

  ## `:node`

  A node is a concrete item. It represents all the concrete items you need to act upon.

  For example, a host, or just an account on a host you need to target.
  Perhaps a piece of software you want to build.

  ## `:other`

  It is allowed to store associated files in the inventory. They get reported with `:other`.
  """
  @type type :: :class | :node | :other

  @typedoc """
  The name for an element.

  The `name` consists of alphanumeric characters and dots.
  """
  # :TODO: implement a verification/validation function
  @type name :: String.t()

  @typedoc """
  The unique identifier for an element.
  """
  @type id :: {type :: type(), name :: name()}

  @typedoc """
  The implementation-specific information about the element.
  """
  @type store_handle() :: %{
          :module => module(),
          optional(atom()) => any
        }

  @typedoc """
  A handle to address one element inside a store.
  """
  @type t ::
          %__MODULE__{
            id: id(),
            store_handle: store_handle()
          }

  @doc """
  A helper function to create one Element instance.

      iex> Element.create({:node, "my.node"}, %{internal_id: 4711})
      {:ok, %Element{id: {:node, "my.node"}, store_handle: %{internal_id: 4711}}}

  > #### INFO {: .info}
  > This function is for the convenience of the specific store implementation. If you need to create
  > an element-id it is advised to use the concrete stores implementation directly.
  """
  @spec create(id :: id(), store_handle :: store_handle()) :: {:ok, t()}
  def create(id, store_handle) do
    {:ok,
     %__MODULE__{
       id: id,
       store_handle: store_handle
     }}
  end

  @doc """
  A helper function to create one Element instance.

      iex> Element.create(:node, "my.node", %{internal_id: 4711})
      {:ok, %Element{id: {:node, "my.node"}, store_handle: %{internal_id: 4711}}}

  > #### INFO {: .info}
  > This function is for the convenience of the specific store implementation. If you need to create
  > an element-id use the concrete stores implementation directly (
  """
  @spec create(type :: type(), name :: name(), store_handle :: store_handle()) :: {:ok, t()}
  def create(type, name, store_handle) do
    {:ok,
     %__MODULE__{
       id: {type, name},
       store_handle: store_handle
     }}
  end

  @doc """
  Get the `id` for the `element`.
  """
  @spec id(element :: t()) :: id()
  def id(element) do
    element.id
  end

  @doc """
  Get the `id` for the `element`.
  """
  @spec name(element :: t()) :: name()
  def name(element) do
    element.id |> elem(1)
  end

  @doc """
  Get the `store_handle` for the `element`.
  """
  @spec store_handle(element :: t()) :: store_handle()
  def store_handle(element) do
    element.store_handle
  end

  @doc """
  Get the `type` for the `element`.
  """
  @spec type(element :: t()) :: type()
  def type(element) do
    element.id |> elem(0)
  end
end
