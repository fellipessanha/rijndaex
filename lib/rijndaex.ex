defmodule Rijndaex do
  @moduledoc """
  Pure-Elixir implementation of the Rijndael (AES) cipher.

  Provides the core building blocks of the AES algorithm:

  - `CypherInput` — validates the cipher key and pads plaintext to 16-byte block boundaries
  - `KeyExpansion` — derives per-round subkeys from the original cipher key (key schedule)
  - `Operations` — shared XOR (`add/2`) used across all cipher steps
  - `Operations.SubBytes` — non-linear byte substitution via the AES S-box
  - `Operations.ShiftRow` — cyclic row permutation over the 4×4 state matrix
  - `Operations.MixColumns` — column mixing via GF(2⁸) matrix multiplication

  ## Examples:
    iex> key = <<0x54, 0x68, 0x61, 0x74, 0x73, 0x20, 0x6D, 0x79, 0x20, 0x4B, 0x75, 0x6E, 0x67, 0x20, 0x46, 0x75>>
    iex> input = <<0x54, 0x77, 0x6F, 0x20, 0x4F, 0x6E, 0x65, 0x20, 0x4E, 0x69, 0x6E, 0x65, 0x20, 0x54, 0x77, 0x6F>>
    iex> Rijndaex.cypher_blocks(key, input)
    <<0x29, 0xC3, 0x50, 0x5F, 0x57, 0x14, 0x20, 0xF6, 0x40, 0x22, 0x99, 0xB3, 0x1A, 0x02, 0xD7, 0x3A>>

  """

  alias Operations.{MixColumns, SubBytes, ShiftRow}
  import Operations, only: [add: 2]
  import Utils, only: [as_matrix: 1]

  @type cypher_strategies() :: :naive | :ecb | :cbc

  @spec cypher_blocks(binary(), binary(), cypher_strategies, keyword) :: binary()
  def cypher_blocks(key, input, strategy \\ :naive, opts \\ [])
  def cypher_blocks(key, input, :naive, _), do: Strategies.Naive.cypher_blocks(key, input)
  def cypher_blocks(key, input, :ecb, _), do: Strategies.ECB.cypher_blocks(key, input)
  def cypher_blocks(key, input, :cbc, _), do: Strategies.CBC.cypher_blocks(key, input)

  @doc """
  Encrypts a single 4×4 matrix block using the expanded key schedule.

  `block` must already be in matrix form (list of 4 four-byte lists), as
  returned by the private `as_matrix/1` helper. `key` is the original cipher
  key (binary or list) used for the initial AddRoundKey step.
  """
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

  @spec uncypher_blocks(binary(), binary(), cypher_strategies) :: binary()
  def uncypher_blocks(key, input, strategy \\ :naive)
  def uncypher_blocks(key, input, :naive), do: Strategies.Naive.uncypher_blocks(key, input)
  def uncypher_blocks(key, input, :ecb), do: Strategies.ECB.uncypher_blocks(key, input)
  def uncypher_blocks(key, input, :cbc), do: Strategies.CBC.uncypher_blocks(key, input)
end
