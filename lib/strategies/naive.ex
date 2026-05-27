defmodule Strategies.Naive do
  @behaviour Strategies.StrategyBehaviour

  import Utils, only: [as_matrix: 1]
  import Operations, only: [add: 2]
  import Strategies.Rounds, only: [cypher_block: 3]
  alias Operations.{MixColumns, SubBytes, ShiftRow}

  @impl true
  def cypher_blocks(key, input) do
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key)

    for block <- parsed_input.blocks, into: <<>> do
      block
      |> as_matrix()
      |> cypher_block(expanded_key, key)
      |> :binary.list_to_bin()
    end
  end

  @impl true
  def uncypher_blocks(key, input) do
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key) |> Enum.reverse()

    for block <- parsed_input.blocks, into: <<>> do
      block
      |> as_matrix()
      |> uncypher_block(expanded_key, key)
      |> :binary.list_to_bin()
    end
  end

  def uncypher_block(block, [last_expanded_key | expanded_keys], key) do
    round_key = key |> as_matrix()

    block
    |> add(last_expanded_key)
    |> ShiftRow.revert()
    |> SubBytes.revert()
    |> revert_rounds(expanded_keys)
    |> add(round_key)
  end

  defp revert_rounds(block, []), do: block

  defp revert_rounds(block, [round_key | other_keys]) do
    block
    |> add(round_key)
    |> MixColumns.revert()
    |> ShiftRow.revert()
    |> SubBytes.revert()
    |> revert_rounds(other_keys)
  end
end
