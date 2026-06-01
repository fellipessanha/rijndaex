defmodule Strategies.ECB do
  @behaviour Strategies.StrategyBehaviour
  import Utils, only: [as_matrix: 1]
  import Strategies.Rounds, only: [cypher_block: 3, uncypher_block: 3]

  @impl true
  def cypher_blocks(key, input) do
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key)

    tasks =
      for block <- parsed_input.blocks do
        Task.async(fn ->
          block
          |> as_matrix()
          |> cypher_block(expanded_key, key)
        end)
      end

    for task <- tasks, into: <<>> do
      Task.await(task)
      |> :binary.list_to_bin()
    end
  end

  @impl true
  def uncypher_blocks(key, input) do
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key) |> Enum.reverse()

    tasks =
      for block <- parsed_input.blocks do
        Task.async(fn ->
          block
          |> as_matrix()
          |> uncypher_block(expanded_key, key)
        end)
      end

    for task <- tasks, into: <<>> do
      Task.await(task)
      |> :binary.list_to_bin()
    end
  end
end
