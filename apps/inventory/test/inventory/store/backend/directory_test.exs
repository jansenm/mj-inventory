defmodule MJ.Inventory.Store.Backend.DirectoryTest do
  use ExUnit.Case

  alias MJ.Inventory.Store.Backend.Directory
  alias MJ.Inventory.ErrorContext

  test "create/1 -> success" do
    assert {:ok, _} = Directory.create(path: "test/inventories/valid/simple")
  end

  test "create/1 -> path does not exists" do
    path = "/tmp/4711384848586877979"
    {:error, error} = Directory.create(path: path)
    assert %ErrorContext{error: :does_not_exist} = error

    assert ErrorContext.to_string(error)
           |> String.contains?(path)

    assert ErrorContext.to_string(error)
           |> String.contains?("not a directory")
  end

  test "create/1 -> path is not a directory" do
    path = "/etc/hostname"
    {:error, error} = Directory.create(path: path)
    assert %ErrorContext{error: :does_not_exist} = error

    assert ErrorContext.to_string(error)
           |> String.contains?(path)

    assert ErrorContext.to_string(error)
           |> String.contains?("not a directory")
  end

  test "create/1 -> path/nodes does not exist" do
    path = "test/inventories/invalid/nodes_missing"
    {:error, error} = Directory.create(path: path)
    assert %ErrorContext{error: :does_not_exist} = error

    assert ErrorContext.to_string(error)
           |> String.contains?(path)

    assert ErrorContext.to_string(error)
           |> String.contains?("does not exist")
  end

  test "create/1 -> path/classes does not exist" do
    path = "test/inventories/invalid/classes_missing"
    {:error, error} = Directory.create(path: path)
    assert %ErrorContext{error: :does_not_exist} = error

    assert ErrorContext.to_string(error)
           |> String.contains?(path)

    assert ErrorContext.to_string(error)
           |> String.contains?("does not exist")
  end

  test "load/2 -> load a existing class" do
    path = "test/inventories/valid/simple"
    assert {:ok, store} = Directory.create(path: path)

    assert {:ok, element} =
             Directory.create_element_id(store, :node, "simple_node",
               format: :yaml,
               path: "nodes/simple_node.yaml"
             )

    assert {:ok, content} = Directory.load(store, element)
    assert File.read!(Path.join(path, "nodes/simple_node.yaml")) == content
  end

  test "load/2 -> load a non-existing class" do
    path = "test/inventories/valid/simple"
    assert {:ok, store} = Directory.create(path: path)

    assert {:ok, element} =
             Directory.create_element_id(store, :node, "does_not_exist",
               format: :yaml,
               path: Path.join(path, "nodes/does_not_exist.yaml")
             )

    {:error, %ErrorContext{error: :ioerror}} = Directory.load(store, element)
  end

  test "list/1 -> only list nodes and classes definition files" do
    path = "test/inventories/valid/simple"
    assert {:ok, store} = Directory.create(path: path)

    assert [
             {:node, "empty_node"},
             {:node, "simple_node"},
             {:other, "classes/.gitkeep"},
             {:other, "nodes/.gitkeep"}
           ] ==
             Directory.list(store)
             |> elem(1)
             |> Stream.map(&elem(&1, 1))
             |> Stream.map(& &1.id)
             |> Enum.into([])
             |> Enum.sort()

  end
end
