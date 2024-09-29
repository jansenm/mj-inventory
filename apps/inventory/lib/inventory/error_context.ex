defmodule MJ.Inventory.ErrorContext do
  @moduledoc """
  Context-information for errors.

  Sometimes errors aren't supposed to be handled by the program itself, they are gathered and presented
  to the user. In those cases in addition to a error code (an atom()) it would be nice to have a human
  readable informational description preferably with some addition context information.

  This module implements this.

  The gathered information is:

  * error is a error code.
  * message is a human readable and translatable message.
  * context are addition informations about the error, which can also get added to the message.

      iex> {:error, err} = ErrorContext.create(
      ...>   :enoent,
      ...>   "No entry %{name} exists",
      ...>   %{name: "/etc/hostname", type: :file}
      ...> )
      iex> err.error
      :enoent
      iex> err.message
      "No entry /etc/hostname exists"
      iex> err.context
      %{name: "/etc/hostname", type: :file}

  The messages will be translated to the current locale with gettext.

      iex> nil = Gettext.put_locale("de")
      iex> {:error, err} = ErrorContext.create(
      ...>   :enoent,
      ...>   "No entry %{name} exists",
      ...>   %{name: "/etc/hostname", type: :file}
      ...> )
      iex> err.error
      :enoent
      iex> err.message
      "Eintrag /etc/hostname existiert nicht"
      iex> err.context
      %{name: "/etc/hostname", type: :file}
      iex> Gettext.put_locale("en")
  """
  # :TODO: document error_message
  @type error :: atom()
  @type message :: String.t()
  @type context :: %{atom() => String.t()} | nil

  @type t :: %__MODULE__{
          error: error(),
          message: message(),
          context: context
        }

  defmacro __using__(_options) do
    quote do
      use Gettext, backend: MJ.Inventory.Gettext
      require MJ.Inventory.ErrorContext, as: ErrorContext
    end
  end

  @enforce_keys [:error, :message]
  defstruct [:error, :message, :context]

  @doc """
  Create a error utilizing the gettext macro.
  """
  @spec create(
          error :: atom(),
          message :: String.t()
        ) :: Macro.t()
  defmacro create(error, message) do
    quote do
      {:error,
       %unquote(__MODULE__){
         error: unquote(error),
         message: dgettext("errors", unquote(message)),
         context: nil
       }}
    end
  end

  @doc """
  Create a error utilizing the gettext macro.
  """
  @spec create(
          error :: atom(),
          message :: String.t(),
          context :: map()
        ) :: Macro.t()
  defmacro create(error, message, context) do
    quote do
      {:error,
       %unquote(__MODULE__){
         error: unquote(error),
         message: dgettext("errors", unquote(message), unquote(context)),
         context: unquote(context)
       }}
    end
  end

  @doc """
  Create a error utilizing the dgettext macro.
  """
  @spec create(
          error :: atom(),
          message :: String.t(),
          message_plural :: String.t(),
          n :: integer(),
          context :: map()
        ) :: Macro.t()
  defmacro create(error, message, message_plural, n, context) do
    quote do
      {:error,
       %unquote(__MODULE__){
         error: unquote(error),
         message:
           dngettext(
             "errors",
             unquote(message),
             unquote(message_plural),
             unquote(n),
             unquote(context)
           ),
         context: unquote(context)
       }}
    end
  end

  @doc """
  Convenience function to create a `:not_implemented` error.
  """
  @spec not_implemented() :: Macro.t()
  defmacro not_implemented() do
    quote do
      function =
        case __ENV__.function do
          nil -> "unknown"
          {func, arity} -> "#{func}/#{arity}"
        end

      context = %{
        module: Atom.to_string(__ENV__.module),
        function: function
      }

      {:error,
       %unquote(__MODULE__){
         error: :not_implemented,
         message:
           dgettext(
             "errors",
             "The function %{module}.'%{function}' is not yet implemented",
             context
           ),
         context: context
       }}
    end
  end

  @doc """
  Converts the error into a human-readable String.
  """
  @spec to_string(error_message :: t()) :: String.t()
  def to_string(%__MODULE__{error: error, message: message}) do
    "#{error}:#{message}"
  end
end
