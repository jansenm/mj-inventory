defmodule MJ.Inventory.StoreTest do
  use ExUnit.Case
  alias MJ.Inventory.Store
  alias MJ.Inventory.Store.Element
  alias MJ.Inventory.Store.Backend.Directory

  test "create" do
    {:ok, store} =
      start_supervised(
        {Store, [backend: Directory, backend_config: [path: "test/inventories/valid/simple"]]}
      )

    assert [
             {:node, "empty_node"},
             {:node, "simple_node"},
           ] ==
             Store.definitions(store)
             |> elem(1)
             |> Stream.map(fn {:ok, elem} -> Element.id(elem) end)
             |> Enum.into([])
             |> Enum.sort()

    {:ok, simple_node_elem}  = Store.Element.create(
      {:node, "simple_node"},
      %{path: "nodes/simple_node.yaml"}
    )

    assert { :ok, """
        # This is just a very simple node without inheritance to check if we can load it.

        parameters:
          integer: 1
          float: 1.0
          string: "Hello World"
          list:
            - 1
            - 2
            - 3
          map:
            hello: world\
        """} == Store.get_source(store, simple_node_elem)
  end
end
