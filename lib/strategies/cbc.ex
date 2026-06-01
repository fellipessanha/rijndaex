defmodule Strategies.CBC do
  @behaviour Strategies.StrategyBehaviour
  import Utils, only: [as_matrix: 1]
  import Operations, only: [add: 2]
  import Strategies.Rounds, only: [cypher_block: 3, uncypher_block: 3]

  @impl true
  def cypher_blocks(key, input, opts \\ []) do
    iv = Keyword.get(opts, :iv, get_initialization_vector(key)) |> :binary.bin_to_list()
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key)

    for block <- parsed_input.blocks, reduce: [] do
      [] ->
        cyphered =
          add(iv, block)
          |> as_matrix()
          |> cypher_block(expanded_key, key)

        [cyphered]

      acc = [last | _] ->
        cyphered =
          block
          |> as_matrix()
          |> add(last)
          |> cypher_block(expanded_key, key)

        [cyphered | acc]
    end
    |> Enum.reverse()
    |> List.flatten()
    |> :binary.list_to_bin()
  end

  @impl true
  def uncypher_blocks(key, input, opts \\ []) do
    iv = Keyword.get(opts, :iv, get_initialization_vector(key)) |> :binary.bin_to_list()
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key) |> Enum.reverse()

    for [previous, current] <- [iv | parsed_input.blocks] |> Enum.chunk_every(2, 1, :discard),
        reduce: [] do
      acc ->
        uncyphered =
          current
          |> as_matrix()
          |> uncypher_block(expanded_key, key)
          |> List.flatten()
          |> add(previous)

        [uncyphered | acc]
    end
    |> Enum.reverse()
    |> List.flatten()
    |> :binary.list_to_bin()
  end

  defp get_initialization_vector(key) do
    :crypto.hash(:md5, key)
  end
end
