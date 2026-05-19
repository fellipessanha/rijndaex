defmodule Operations.MixColumns do
  @moduledoc """
  Implements the MixColumns step of the AES cipher.

  Treats each column of the 4×4 state matrix as a polynomial over GF(2⁸) and
  multiplies it by a fixed polynomial, providing diffusion across column bytes.
  The reduction polynomial is x⁸ + x⁴ + x³ + x + 1 (0x11B).

  ## Examples

      iex> Operations.MixColumns.apply([99, 71, 162, 240])
      [93, 224, 112, 187]

      iex> Operations.MixColumns.revert([93, 224, 112, 187])
      [99, 71, 162, 240]

      iex> Operations.MixColumns.apply([242, 10, 34, 92])
      [159, 220, 88, 157]

      iex> Operations.MixColumns.revert([159, 220, 88, 157])
      [242, 10, 34, 92]
  """
  import Bitwise, only: [&&&: 2, <<<: 2, >>>: 2, bxor: 2]

  @inverse_matrix [
    [14, 11, 13, 9],
    [9, 14, 11, 13],
    [13, 9, 14, 11],
    [11, 13, 9, 14]
  ]

  defp add(a, b), do: bxor(a, b)

  @spec mul(non_neg_integer(), non_neg_integer()) :: non_neg_integer()
  @doc """
  Multiplies two values in GF(2⁸) using the AES reduction polynomial.

  ## Examples

      iex> Operations.MixColumns.mul(3, 5)
      15
      iex> Operations.MixColumns.mul(0x57, 0x13)
      0xFE
  """
  def mul(a, b), do: mul(a, b, 0)
  defp mul(_, 0, result), do: result

  defp mul(a, b, acc) do
    acc = if (b &&& 1) != 0, do: add(acc, a), else: acc
    mul(mul2(a), b >>> 1, acc)
  end

  defp mul2(a) when (a &&& 0x80) != 0,
    do: (a <<< 1) |> add(0x1B) |> rem(0x100)

  defp mul2(a), do: (a <<< 1) |> rem(0x100)

  @spec apply([non_neg_integer()]) :: [non_neg_integer()]
  @doc """
  Applies the MixColumns transformation to a single column (list of 4 bytes).

  Each output byte is derived from all four input bytes via GF(2⁸) arithmetic,
  providing diffusion within the column.

  ## Examples

      iex> Operations.MixColumns.apply([99, 71, 162, 240])
      [93, 224, 112, 187]
  """
  def apply(block = [first | _]) when is_list(first), do: Enum.map(block, &apply/1)

  def apply(row = [item | _]) when is_integer(item) do
    xored = Enum.reduce(row, &add/2)

    row
    |> Enum.chunk_every(2, 1, row)
    |> Enum.map(fn [a, b] ->
      mul2(add(a, b)) |> add(xored) |> add(a)
    end)
  end

  @spec revert([non_neg_integer()]) :: [non_neg_integer()]
  @doc """
  Applies the inverse MixColumns transformation to a single column (list of 4 bytes).

  Recovers the original column from a MixColumns-transformed one using the
  AES inverse matrix over GF(2⁸).

  ## Examples

      iex> Operations.MixColumns.revert([93, 224, 112, 187])
      [99, 71, 162, 240]
  """
  def revert(column) do
    for row <- @inverse_matrix do
      Enum.zip(column, row)
      |> Enum.map(fn {a, b} -> mul(a, b) end)
      |> Enum.reduce(&add/2)
    end
  end
end
