defmodule MJ.Inventory.Store do
  @moduledoc """
  Storage for `t:MJ.Inventory.Store.Element.t()` elements.

  The store can utilize several backends to address different storage options.

  ## Element Version

  Each element can be acquired from the store in two different versions.

  ### Source

  The source version is the unparsed human readable definition from the store. It's
  the raw unparsed Yaml or Toml markup as a `String.t`.

  ### Parsed

  The *parsed* version is the result of parsing the *source* version with the appropriate markup
  parser.
  """

  defmodule Backend do
    @moduledoc """
    Behaviour for a Store-Backend Implementation.
    """
    alias MJ.Inventory.Error
    alias MJ.Inventory.Store.Element

    @typedoc """
    The Backend-specific options.

    This could be database connection details or a filesystem path.
    """
    @type config :: Keyword.t(any())

    @typedoc """
    The handle for the backend.
    """
    @type t :: %{}

    @doc """
    Create a backend.

    > #### Important {: .warning}
    > The function *HAS TO* check that
    >
    > * the given `options` are valid,
    > * the store exists,
    > * it is properly initialized and usable.
    """
    @callback create(config :: config()) :: {:ok, t()} | Error.context_t()

    @doc """
    Create an element id.

        iex>  Backend.create_element_id(
        ...>    %{},
        ...>    :class ,
        ...>    "distribution.suse",
        ...>    [ format: :yaml, path: "classes/distribution.suse.yml" ]

    This function is implementation-dependent. It might not be possible to create a new element
    without knowledge of the underlying storage backend.

    This is especially the case for the `MJ.Inventory.Store.Backend.Directory` module. For classes
    path and class-name are related but not unique.

    | Path                          | Class Id          |
    | ---                           | ---               |
    | classes/dot/com/bubble.yaml   | dot.com.bubble    |
    | classes/dot.com.bubble.yaml   | dot.com.bubble    |

    Because of that the directory store keeps the path inside the
    `t:MJ.Inventory.Store.Element.store_handle/0`. For that reason, it is preferable to interact with
    the specific store implementation to create element ids.
    """
    @callback create_element_id(
                config :: t(),
                type :: Element.type(),
                name :: Element.name(),
                options :: Keyword.t()
              ) ::
                {:ok, Element.t()} | Error.context_t()

    @doc """
    Stream all elements contained in `backend`.
    """
    @callback list(config :: t()) :: {:ok, Enumerable.t(Element.t())} | Error.context_t()

    @doc """
    Load one `element` from `backend` and return the `definition`.
    """
    @callback load(config :: t(), element :: Element.t()) ::
                definition :: {:ok, String.t()} | Error.context_t()

    @doc """
    Save the `definition` for `element` in `backend`.
    """
    @callback save(config :: t(), element :: Element.t(), content :: String.t()) ::
                :ok | Error.context_t()

    @doc """
    Remove the `element` from the `backend`.
    """
    @callback delete(config :: t(), element :: Element.t()) :: :ok | Error.context_t()
  end

  alias MJ.Inventory.Error
  alias MJ.Inventory.Store.Element

  @typedoc """
  The handle for a `MJ.Inventory.Store`.
  """
  @opaque t :: GenServer.name()

  ###
  ### API
  ###

  @spec get_parsed(store :: t(), element :: Element.t()) ::
          {:ok, parsed :: map()} | Error.context_t()
  def get_parsed(store, element) do
    GenServer.call(store, {:get_parsed, element})
  end

  @spec get_source(store :: t(), element :: Element.t()) ::
          {:ok, source :: String.t()} | Error.context_t()
  def get_source(store, element) do
    GenServer.call(store, {:get_source, element})
  end

  @spec list(store :: t()) :: {:ok, files :: Enumerable.t(Element.t())} | Error.t()
  def list(store) do
    GenServer.call(store, :list)
  end

  @spec definitions(store :: t()) :: {:ok, files :: Enumerable.t(Element.t())} | Error.t()
  def definitions(store) do
    {:ok, stream } = GenServer.call(store, :list)
    {:ok, stream |> Stream.filter(fn {:ok, el} -> el.id |> elem(0) != :other end)}
  end

  @spec put(store :: t(), element :: Element.t(), content :: String.t()) ::
              :ok | Error.t()
  def put(store, element, content) do
    GenServer.call(store, {:put, element, content})
  end

  ###
  ### GenServer Implementation
  ###
  @behaviour GenServer

  @doc """
    :TODO:
  """
  def child_spec(init_arg) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, init_arg]}
    }
  end

  @impl GenServer
  def handle_call(:list, _from, state) do
    {:reply, state.be_module.list(state.be_config), state}
  end

  @impl GenServer
  def handle_call({:get_source, element}, _from, state) do
    {:reply, state.be_module.load(state.be_config, element), state}
  end

  @impl GenServer
  def handle_call(_msg, _from, state) do
    {:reply, {:error, :not_implemented}, state}
  end

  @impl GenServer
  def init(config) do
    {backend_module, config} = Keyword.pop(config, :backend)
    {backend_config, config} = Keyword.pop(config, :backend_config, [])

    if config != [] do
      raise "init: unknown parameters encountered #{inspect(config)}}"
    end

    case backend_module.create(backend_config) do
      {:ok, backend} ->
        {:ok,
          %{
            be_module: backend_module,
            be_config: backend
          }}

      {:error, reason} ->
        {:stop, reason}
    end
  end
end
