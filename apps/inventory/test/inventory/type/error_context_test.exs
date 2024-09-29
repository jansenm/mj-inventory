defmodule MJ.Inventory.ErrorContextTest do
  use ExUnit.Case, async: true

  use Gettext, backend: MJ.Inventory.Gettext

  require MJ.Inventory.ErrorContext, as: ErrorContext

  doctest ErrorContext

  test "ErrorContext.create/2" do
    assert {:error,
            %ErrorContext{
              error: :not_implemented,
              message: "Not implemented",
              context: nil
            }} =
             ErrorContext.create(
               :not_implemented,
               "Not implemented"
             )
  end

  test "ErrorContext.create/3" do
    assert {:error,
            %{
              error: :function_not_implemented,
              message: "Function main not implemented",
              context: %{name: "main"}
            }} =
             ErrorContext.create(
               :function_not_implemented,
               "Function %{name} not implemented",
               %{name: "main"}
             )
  end

  test "ErrorContext.to_string/1" do
    assert "function_not_implemented:Function main not implemented" ==
             ErrorContext.to_string(
               ErrorContext.create(
                 :function_not_implemented,
                 "Function %{name} not implemented",
                 %{name: "main"}
               )
               |> elem(1)
             )
  end

  test "ErrorContext.not_implemented/0" do
    assert "not_implemented:The function Elixir.MJ.Inventory.ErrorContextTest.'test ErrorContext.not_implemented/0/1' is not yet implemented"
             ErrorContext.to_string(ErrorContext.not_implemented() |> Kernel.elem(1))
  end
end
