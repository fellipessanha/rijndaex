defmodule Strategies.Rounds do
  alias Operations.{MixColumns, SubBytes, ShiftRow}
  import Operations, only: [add: 2]
  import Utils, only: [as_matrix: 1]

  def cypher_block(block, expanded_key, key) do
    round_key = key |> as_matrix()

    add(block, round_key)
    |> apply_rounds(expanded_key)
  end

  defp apply_rounds(block, [round_key]) do
    block
    |> SubBytes.apply()
    |> ShiftRow.apply()
    |> add(round_key)
  end

  defp apply_rounds(block, [round_key | other_keys]) do
    block
    |> SubBytes.apply()
    |> ShiftRow.apply()
    |> MixColumns.apply()
    |> add(round_key)
    |> apply_rounds(other_keys)
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
