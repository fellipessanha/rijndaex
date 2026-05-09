defmodule Rijndaex.Operations.MixColumns do
  @moduledoc """
  Specific _multiplication_ operation used in this algorithm.

  it's a mix of bitwise xors and rightshifts in b operation.

    iex> Rijndaex.Operations.MixColumns.apply([99, 71, 162, 240])
    [93, 224, 112, 187]

    iex> Rijndaex.Operations.MixColumns.revert([93, 224, 112, 187])
    [99, 71, 162, 240]

    iex> Rijndaex.Operations.MixColumns.apply([242, 10, 34, 92])
    [159, 220, 88, 157]

    iex> Rijndaex.Operations.MixColumns.revert([159, 220, 88, 157])
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

  def mul(a, b), do: mul(a, b, 0)
  defp mul(_, 0, result), do: result

  defp mul(a, b, acc) do
    acc = if (b &&& 1) != 0, do: add(acc, a), else: acc
    mul(mul2(a), b >>> 1, acc)
  end

  defp mul2(a) when (a &&& 0x80) != 0,
    do: (a <<< 1) |> add(0x1B) |> rem(0x100)

  defp mul2(a), do: (a <<< 1) |> rem(0x100)

  def apply(column) do
    xored = Enum.reduce(column, &add/2)

    column
    |> Enum.chunk_every(2, 1, column)
    |> Enum.map(fn [a, b] ->
      mul2(add(a, b)) |> add(xored) |> add(a)
    end)
  end

  def revert(column) do
    for row <- @inverse_matrix do
      Enum.zip(column, row)
      |> Enum.map(fn {a, b} -> mul(a, b) end)
      |> Enum.reduce(&add/2)
    end
  end
end
