defmodule Rijndaex.Operations.MixColumns do
  def add(a, b), do: Bitwise.bxor(a, b)

  @doc """
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

  @inverse_matrix [
    [14, 11, 13, 9],
    [9, 14, 11, 13],
    [13, 9, 14, 11],
    [11, 13, 9, 14]
  ]

  def mul(a, b), do: mul(a, b, 0)
  defp mul(_, 0, result), do: result

  defp mul(a, b, acc) do
    acc = if Bitwise.&&&(b, 1) != 0, do: Bitwise.bxor(acc, a), else: acc
    mul(mul2(a), Bitwise.>>>(b, 1), acc)
  end

  defp mul2(a) when Bitwise.&&&(a, 0x80) != 0,
    do: Bitwise.<<<(a, 1) |> Bitwise.bxor(0x1B) |> rem(0x100)

  defp mul2(a), do: Bitwise.<<<(a, 1) |> rem(0x100)

  def apply(column) do
    xored = Enum.reduce(column, &Bitwise.bxor/2)

    column
    |> Enum.chunk_every(2, 1, column)
    |> Enum.map(fn [a, b] ->
      mul2(Bitwise.bxor(a, b)) |> Bitwise.bxor(xored) |> Bitwise.bxor(a)
    end)
  end

  def revert(column) do
    for row <- @inverse_matrix do
      Enum.zip(column, row)
      |> Enum.map(fn {a, b} -> mul(a, b) end)
      |> Enum.reduce(&Bitwise.bxor/2)
    end
  end
end
