defmodule MJ.Inventory.Store.Backend.Parser.YamlTest do
  use ExUnit.Case

  alias MJ.Inventory.Store.Parser.Yaml, as: YamlParser

  @moduletag :capture_log

  doctest YamlParser

  describe "parser handles valid yaml" do
    test "empty string" do
      assert YamlParser.parse("") == [nil]
    end

    test "parser handles valid empty yaml stream" do
      assert YamlParser.parse("---") == [nil]
    end

    test "parser handles valid empty multi document yaml stream" do
      assert YamlParser.parse("""
             ---
             ---
             """) == [nil, nil]
    end

    test "parser handles valid multi document yaml stream" do
      assert YamlParser.parse("""
             ---
             parameters:
             ---
             classes:
             """) == [%{"parameters" => nil}, %{"classes" => nil}]
    end

    test "parser handles valid yaml top level list" do
      assert YamlParser.parse("""
             ---
             - 1
             - 2
             """) == [[1, 2]]
    end
  end

  # describe

  test "parser transforms all yaml datatypes" do
    # We are not unit testing yamerl here. We test our transform functions.
    assert YamlParser.parse("""
           "null": null
           "bool": true
           bool2: yes
           integer: 42
           float: 47.11
           negative: -1.1
           zero: 0.
           """) ==
             [
               %{
                 "null" => nil,
                 "bool" => true,
                 # Yaml Spec say yes/no is not a bool https://yaml.org/spec/1.2.2/#10212-boolean
                 "bool2" => "yes",
                 "integer" => 42,
                 "float" => 47.11,
                 "negative" => -1.1,
                 "zero" => 0.0
               }
             ]
  end

  test "parser handles invalid yaml" do
    assert {:error, reason} =
             YamlParser.parse("""
             ---
             parameters:
              - one
              - two
              three: test
             """)

    assert :parsing_error = reason.error
    assert "Parsing error at" <> _rest = reason.message
    assert 5 = reason.context.line
    assert 2 = reason.context.char
  end
end
