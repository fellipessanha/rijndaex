defmodule RijndaexTest do
  use ExUnit.Case
  doctest Rijndaex
  doctest CypherInput
  doctest KeyExpansion

  test "greets the world" do
    assert Rijndaex.hello() == :world
  end
end
