defmodule Rijndaex do
  @moduledoc """
  Pure-Elixir implementation of the Rijndael (AES) cipher.

  Provides the core building blocks of the AES algorithm:

  - `CypherInput` — validates the cipher key and pads plaintext to 16-byte block boundaries
  - `KeyExpansion` — derives per-round subkeys from the original cipher key (key schedule)
  - `Operations.SubBytes` — non-linear byte substitution via the AES S-box
  - `Operations.ShiftRow` — cyclic row permutation over the 4×4 state matrix
  - `Operations.MixColumns` — column mixing via GF(2⁸) matrix multiplication

  ## Examples:
    iex> key = <<0x54, 0x68, 0x61, 0x74, 0x73, 0x20, 0x6D, 0x79, 0x20, 0x4B, 0x75, 0x6E, 0x67, 0x20, 0x46, 0x75>>
    iex> input = <<0x54, 0x77, 0x6F, 0x20, 0x4F, 0x6E, 0x65, 0x20, 0x4E, 0x69, 0x6E, 0x65, 0x20, 0x54, 0x77, 0x6F>>
    iex> Rijndaex.entrypoint(key, input)
    <<0x29, 0xC3, 0x50, 0x5F, 0x57, 0x14, 0x20, 0xF6, 0x40, 0x22, 0x99, 0xB3, 0x1A, 0x02, 0xD7, 0x3A>>

  """

  alias Operations.{MixColumns, SubBytes, ShiftRow}

  def entrypoint(key, input) do
    {:ok, parsed_input} = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key)

    for block <- parsed_input.blocks, into: <<>> do
      cypher_block(block, expanded_key, key) |> :binary.list_to_bin()
    end
  end

  def cypher_block(block, expanded_key, key) do
    block = KeyExpansion.add(block, :binary.bin_to_list(key))
    blockstring = block |> Enum.map(&Integer.to_string(&1, 16)) |> Enum.join(", ")
    IO.puts("xoring #{inspect(block)} O #{inspect(key)} = #{inspect(blockstring)}")

    block |> apply_rounds(expanded_key)
  end

  defp apply_rounds(block, keys = [round_key]) do
    IO.puts("applying rounds: #{inspect(keys)}")

    block =
      block
      |> SubBytes.apply()
      |> ShiftRow.apply()
      |> KeyExpansion.add(round_key)

    IO.puts("last block: #{block |> Enum.map(&Integer.to_string(&1, 16))}")
    block
  end

  defp apply_rounds(block, keys = [round_key | other_keys]) do
    block =
      block
      |> SubBytes.apply()
      |> ShiftRow.apply()
      |> MixColumns.apply()
      |> KeyExpansion.add(round_key)

    remain_size = length(keys)
    IO.puts("#{remain_size} blocks remainig: #{block |> Enum.map(&Integer.to_string(&1, 16))}")
    block |> apply_rounds(other_keys)
  end
end
