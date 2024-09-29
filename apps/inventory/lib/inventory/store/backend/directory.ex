defmodule MJ.Inventory.Store.Backend.Directory do
  @moduledoc """
  A filesystem-based backend implementation.

  A `MJ.Inventory.Store.Backend` implementation that stores the elements in a directory on
  the filesystem.

  See `MJ.Inventory.Store.Backend`.

  ## Layout

  Inside the stores directory the layout is:

  | Path          |                                           |
  | ---           | ---                                       |
  | nodes/        | subdirectory with the node definitions    |
  | classes/      | subdirectory with the class definitions   |

  ## Naming Convention

  The name of an object is derived from its filesystem path.

  The namespaces of nodes and classes are distinct. It is possible to have a node and class with the
  same name.

  ### Classes

  For classes, the path under the classes directory becomes the name with all slashes substituted
  with a dot.

  | Path                                      | Name                          |
  | ---                                       | ---                           |
  | classes/distribution/opensuse.yml         | distribution.opensuse         |
  | classes/domain/michael-jansen.biz.yml     | domain.michael-jansen.biz     |

  The rule stems from reclass. I personally don't like it because as the second example shows, you
  can't infer the path back from the resulting name.

  ### Nodes

  For nodes, the filename becomes the name. Subdirectories under nodes are discarded.

  | Path                                      | Name                          |
  | ---                                       | ---                           |
  | nodes/host/michael-jansen.biz.yml         |michael-jansen.biz             |
  """

  @behaviour MJ.Inventory.Store.Backend

  use MJ.Inventory.ErrorContext, as: ErrorContext

  alias MJ.Inventory.Store.Element
  alias MJ.Inventory.Error
  alias MJ.Inventory.Store.Parser

  require Logger

  @enforce_keys [:path]

  @typedoc """
  The handle for this backend.

  It contains the *absolute* `path` for the store.
  """
  @type t :: %__MODULE__{
          path: String.t()
        }
  defstruct [:path]

  @type format :: Parser.format()

  @typedoc """
  A backend-specific handle for an element.
  """
  @type element_handle :: %{
          format: format(),
          path: String.t()
        }

  @doc """
  Create the backend handle.

  The function checks the following requirements:

  * `path` exists and is a directory
  * `path`/nodes exists and is a directory
  * `path`/classes exists and is a directory
  """
  @impl MJ.Inventory.Store.Backend
  def create(config) do
    {storage_path, config} = Keyword.pop(config, :path)

    if config != [] do
      raise "init: unknown parameters encountered #{inspect(config)}}"
    end

    backend = %__MODULE__{path: Path.absname(storage_path)}

    case exists(backend) do
      :ok -> {:ok, backend}
      e = {:error, _} -> e
    end
  end

  @doc """
  Create a backend-specific handle for an element.

  See `c:MJ.Inventory.Store.Backend.create_element_id/4`.
  """
  @impl MJ.Inventory.Store.Backend
  @spec create_element_id(
          store :: t(),
          type :: Element.type(),
          name :: Element.name(),
          options :: [format: format(), path: String.t()]
        ) ::
          {:ok, Element.t()} | Error.t()
  def create_element_id(_backend, element_type, element_name, options) do
    {format, options} = Keyword.pop(options, :format)
    {path, options} = Keyword.pop(options, :path)

    if options != [] do
      raise "unknown parameters encountered #{inspect(options)}}"
    end

    Element.create(element_type, element_name, %{module: __MODULE__, format: format, path: path})
  end

  @doc """
  Delete one element from the backend.

  See `c:MJ.Inventory.Store.Backend.delete/2`.
  """
  @impl MJ.Inventory.Store.Backend
  def delete(_backend, _element) do
    ErrorContext.not_implemented()
  end

  @doc """
  List all files in the backend.

  See `c:MJ.Inventory.Store.Backend.list/1`.
  """
  @impl MJ.Inventory.Store.Backend
  def list(backend) do
    {:ok,
     Stream.concat([
       index_classes(backend),
       index_nodes(backend)
     ])}
  end

  @doc """
  Load one element from the backend.

  See `c:MJ.Inventory.Store.Backend.load/2`.
  """
  @impl MJ.Inventory.Store.Backend
  def load(backend, %Element{store_handle: store_handle}) do
    case File.read(Path.join(backend.path, store_handle.path)) do
      {:ok, content} ->
        {:ok, content}

      {:error, :enoent} ->
        ErrorContext.create(
          :ioerror,
          "File %{path}: does not exist",
          %{path: store_handle.path}
        )

      {:error, :eacces} ->
        ErrorContext.create(
          :ioerror,
          "File %{path}: no permission to read",
          %{path: store_handle.path}
        )

      {:error, :eisdir} ->
        ErrorContext.create(
          :ioerror,
          "File %{path}: is a directory",
          %{path: store_handle.path}
        )

      {:error, :enomem} ->
        ErrorContext.create(
          :ioerror,
          "File %{path}: not enough memory",
          %{path: store_handle.path}
        )

      {:error, error} ->
        ErrorContext.create(
          :ioerror,
          "File.read() failed with error %{error}",
          %{error: error}
        )
    end
  end

  @doc """
  Save one element in the backend.

  See `c:MJ.Inventory.Store.Backend.save/3`.
  """
  @impl MJ.Inventory.Store.Backend
  def save(_backend, _element, _content) do
    ErrorContext.not_implemented()
  end

  #
  ### PRIVATE
  #

  defp class_name_from_path(classes_dir, path) do
    String.replace(
      relative_path(classes_dir, path),
      "/",
      "."
    )
  end

  defp ensure_root_path_valid(backend) do
    case File.dir?(backend.path) do
      true ->
        :ok

      false ->
        ErrorContext.create(
          :does_not_exist,
          "Storage directory %{path} does not exist or is not a directory",
          %{path: backend.path}
        )
    end
  end

  defp ensure_root_path_has_nodes_dir(backend) do
    case File.dir?(Path.join(backend.path, "nodes")) do
      true ->
        :ok

      false ->
        ErrorContext.create(
          :does_not_exist,
          "Storage directory %{path} does not exist or is not a directory",
          %{path: Path.join(backend.path, "nodes")}
        )
    end
  end

  defp ensure_root_path_has_classes_dir(backend) do
    case File.dir?(Path.join(backend.path, "classes")) do
      true ->
        :ok

      false ->
        ErrorContext.create(
          :does_not_exist,
          "Storage directory %{path} does not exist or is not a directory",
          %{path: Path.join(backend.path, "classes")}
        )
    end
  end

  defp exists(backend) do
    with :ok <- ensure_root_path_valid(backend),
         :ok <- ensure_root_path_has_classes_dir(backend),
         :ok <- ensure_root_path_has_nodes_dir(backend) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # :TODO: Is this correct? bitstring?
  @spec format(path :: String.t()) :: format()
  defp format(path) when is_bitstring(path), do: format_by_suffix(Path.extname(path))
  defp format_by_suffix(".yml"), do: :yaml
  defp format_by_suffix(".yaml"), do: :yaml
  defp format_by_suffix(".YAML"), do: :yaml
  defp format_by_suffix(_), do: :other

  defp index_classes(backend) do
    classes_dir = Path.absname(Path.join(backend.path, "classes"))

    TreeWalker.stream(classes_dir)
    |> Stream.map(fn path ->
      case format(path) do
        :other ->
          create_element_id(backend, :other, relative_path(backend.path, path),
            format: :other,
            path: relative_path(backend.path, path)
          )
        format ->
          create_element_id(backend, :class, class_name_from_path(classes_dir, path),
            format: format,
            path: relative_path(backend.path, path)
          )
      end
    end)
  end

  defp index_nodes(backend) do
    nodes_dir = Path.absname(Path.join(backend.path, "nodes"))

    TreeWalker.stream(nodes_dir)
    |> Stream.map(fn path ->
      case format(path) do
        :other ->
          create_element_id(backend, :other, relative_path(backend.path, path),
            format: :other,
            path: relative_path(backend.path, path)
          )
        format ->
          create_element_id(backend, :node, node_name_from_path(nodes_dir, path),
            format: format,
            path: relative_path(backend.path, path)
          )
      end
    end)
  end

  defp node_name_from_path(_, path) do
    Path.rootname(Path.basename(path))
  end

  defp relative_path(root, path) do
    Path.relative_to(path, root)
  end

end
