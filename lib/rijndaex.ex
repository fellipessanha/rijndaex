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

  @type cypher_strategies() :: :naive | :ecb | :cbc

  @spec cypher_blocks(binary(), binary(), cypher_strategies, keyword) :: binary()
  def cypher_blocks(key, input, strategy \\ :naive, opts \\ [])
  def cypher_blocks(key, input, :naive, _), do: Strategies.Naive.cypher_blocks(key, input)
  def cypher_blocks(key, input, :ecb, _), do: Strategies.ECB.cypher_blocks(key, input)
  def cypher_blocks(key, input, :cbc, _), do: Strategies.CBC.cypher_blocks(key, input)

  @spec uncypher_blocks(binary(), binary(), cypher_strategies) :: binary()
  def uncypher_blocks(key, input, strategy \\ :naive)
  def uncypher_blocks(key, input, :naive), do: Strategies.Naive.uncypher_blocks(key, input)
  def uncypher_blocks(key, input, :ecb), do: Strategies.ECB.uncypher_blocks(key, input)
  def uncypher_blocks(key, input, :cbc, _), do: Strategies.CBC.cypher_blocks(key, input)
end
