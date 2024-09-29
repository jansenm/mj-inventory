defmodule MJ.Inventory.Error do

  alias MJ.Inventory.ErrorContext

  @moduledoc """
  Error definitions for MJ Inventory.
  """

  @typedoc """
  A `MJ.Inventory` error.

  This is a convenience type to enforce consistent error reporting.
  """
  @type t() :: {:error, reason :: atom()}

  @typedoc """
  A `MJ.Inventory` error type.

  This is a convenience type to enforce consistent error reporting.
  """
  @type t(error_type) :: {:error, reason :: error_type}

  @typedoc """
  A `MJ.Inventory` error type.

  This is a convenience type to enforce consistent error reporting.
  """
  @type context_t() :: {:error, reason :: ErrorContext.t()}

end
