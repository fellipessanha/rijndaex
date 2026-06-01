defmodule Strategies.StrategyBehaviour do
  @callback cypher_blocks(input :: binary(), key :: binary()) :: binary()
  @callback uncypher_blocks(input :: binary(), key :: binary()) :: binary()
end
