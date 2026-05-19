defmodule KeyExpansion do
  @moduledoc """
  Implements the AES key schedule (key expansion algorithm).

  Derives all per-round subkeys from the original cipher key. The key schedule
  follows the NIST AES specification: for each round, the last word of the
  previous key undergoes RotWord → SubWord → XOR with the round constant, then
  each subsequent word is XORed with the preceding expanded word.

  Supports 128-bit (10 rounds), 192-bit (12 rounds), and 256-bit (14 rounds) keys.

  ## Examples

      iex> key = for _ <- 1..16, into: <<>>, do: <<0>>
      iex> first_round = KeyExpansion.expand_key(key, 1) |> :binary.list_to_bin()
      <<0x62, 0x63, 0x63, 0x63, 0x62, 0x63, 0x63, 0x63, 0x62, 0x63, 0x63, 0x63, 0x62, 0x63, 0x63, 0x63>>
      iex> KeyExpansion.expand_key(first_round, 2) |> :binary.list_to_bin()
      <<0x9b, 0x98, 0x98, 0xc9, 0xf9, 0xfb, 0xfb, 0xaa, 0x9b, 0x98, 0x98, 0xc9, 0xf9, 0xfb, 0xfb, 0xaa>>
  """
  @word_size 4
  @valid_keysizes [128, 192, 256]
  @round_constants [0x7D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36]
                   |> :array.from_list()

  defstruct [:round_number, :key_size]

  @spec expand_key(binary() | [non_neg_integer()]) :: [[non_neg_integer()]]
  @doc """
  Expands a cipher key into all round keys for a full AES encryption.

  Accepts a binary or a list of bytes. Returns a list where the first element is
  the original key bytes and each subsequent element is the expanded key for that round.
  The total length equals the number of rounds plus one (original key).

  ## Examples

      iex> key = for _ <- 1..16, into: <<>>, do: <<0>>
      iex> all_keys = KeyExpansion.expand_key(key)
      iex> length(all_keys)
      11
      iex> hd(all_keys)
      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  """
  def expand_key(key) when is_binary(key),
    do: key |> :binary.bin_to_list() |> expand_key()

  def expand_key(key) when is_list(key) do
    round_count = key |> key_bitsize() |> CypherInput.n_round_keys()

    {_, expansion} =
      Enum.reduce(1..round_count, [], fn
        round_n, list when is_list(list) ->
          last_iteration = expand_key(key, round_n)
          {last_iteration, [last_iteration | list]}

        round_n, {last, acc} ->
          last_iteration = expand_key(last, round_n)
          {last_iteration, [last_iteration | acc]}
      end)

    [key | Enum.reverse(expansion)]
  end

  @spec expand_key(binary() | [non_neg_integer()], pos_integer()) :: [non_neg_integer()]
  @doc """
  Derives the expanded key for a single round from the preceding key.

  Applies RotWord → SubWord → XOR round constant → XOR previous words.
  Returns a flat list of bytes representing the round key for `round_number`.

  ## Examples

      iex> key = for _ <- 1..16, into: <<>>, do: <<0>>
      iex> KeyExpansion.expand_key(key, 1) |> length()
      16
  """
  def expand_key(key, round_number) when is_list(key) or is_binary(key) do
    key = key_to_words(key)
    context = %__MODULE__{round_number: round_number, key_size: length(key) * @word_size * 8}
    iterate_words(key, context) |> List.flatten()
  end

  defp add(left, right) when is_list(left) and is_list(right),
    do: Enum.map(Enum.zip(left, right), &add/1)

  defp add(left, right), do: Bitwise.bxor(left, right)
  defp add({left, right}), do: Bitwise.bxor(left, right)

  defp add_round_constant([word | rest], current_round) do
    updated = current_round |> :array.get(@round_constants) |> add(word)
    [updated | rest]
  end

  defp iterate_words(words, %__MODULE__{round_number: round_number}) do
    initial =
      words
      |> List.last()
      |> Operations.ShiftRow.rotate()
      |> Operations.SubBytes.apply()
      |> add_round_constant(round_number)

    iterate_words(words, initial, [])
  end

  defp iterate_words([], _, acc), do: Enum.reverse(acc)

  defp iterate_words([word | words], last, acc) do
    xored = add(word, last)
    iterate_words(words, xored, [xored | acc])
  end

  defp key_bitsize(key) when is_binary(key), do: bit_size(key)
  defp key_bitsize(key) when is_list(key), do: 8 * length(key)

  defp key_to_words(key, chunk_size \\ @word_size)

  defp key_to_words(key, chunk_size)
       when is_binary(key) and bit_size(key) in @valid_keysizes do
    key |> :binary.bin_to_list() |> key_to_words(chunk_size)
  end

  defp key_to_words(key, chunk_size) when is_list(key) do
    key |> Enum.chunk_every(chunk_size, chunk_size, :discard)
  end
end
