defmodule KeyExpansion do
  @moduledoc """
  Should receive a Binary `key`, of bitsize 128, 192, or 256 and return the expanded key

  ## Examples:
    iex> key = for _ <- 1..16, into: <<>>, do: <<0>>
    iex> KeyExpansion.expand_key(key, 1)
    [ [0x62, 0x63, 0x63, 0x63], [0x62, 0x63, 0x63, 0x63], 
      [0x62, 0x63, 0x63, 0x63], [0x62, 0x63, 0x63, 0x63]]
  """
  @word_size 4
  @valid_keysizes [128, 192, 256]
  @round_constants [0x7D, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36]
                   |> :array.from_list()

  defstruct [:round_number, :key_size]

  defp add(left, right) when is_list(left) and is_list(right),
    do: Enum.map(Enum.zip(left, right), &add/1)

  defp add(left, right), do: Bitwise.bxor(left, right)
  defp add({left, right}), do: Bitwise.bxor(left, right)

  defp add_round_constant([word | rest], current_round, key_size) do
    updated =
      rem(current_round, CypherInput.n_round_keys(key_size))
      |> :array.get(@round_constants)
      |> add(word)

    [updated | rest]
  end

  @doc """
  Key expansion algorithm per round.

  """

  def expand_key(key, round_number) when is_binary(key) do
    context = %__MODULE__{round_number: round_number, key_size: bit_size(key)}
    key |> key_to_words() |> expand_key(context)
  end

  def expand_key(key, context) when is_list(key) do
    iterate_words(key, context)
  end

  defp iterate_words(words, %__MODULE__{round_number: round_number, key_size: key_size}) do
    initial =
      words
      |> List.last()
      |> Operations.ShiftRow.rotate()
      |> Operations.SubBytes.apply()
      |> add_round_constant(round_number, key_size)

    iterate_words(words, initial, [])
  end

  defp iterate_words([], _, acc), do: acc

  defp iterate_words([word | words], last, acc) do
    xored = add(word, last)
    iterate_words(words, xored, acc ++ [xored])
  end

  defp key_to_words(key, chunk_size \\ @word_size)
       when is_binary(key) and bit_size(key) in @valid_keysizes do
    key |> :binary.bin_to_list() |> Enum.chunk_every(chunk_size, chunk_size, :discard)
  end
end
