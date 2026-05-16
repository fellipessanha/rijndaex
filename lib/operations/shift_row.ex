defmodule Operations.ShiftRow do
  @moduledoc """
  Shifts the ith row by i elements.

  Supposed to be used in Rijndael in 4x4 byte matrixes.

  The example islustrates the effects:

  Example:

    iex> matrix = [
    ...>   [11, 12, 13, 14],
    ...>   [21, 22, 23, 24],
    ...>   [31, 32, 33, 34],
    ...>   [41, 42, 43, 44]
    ...> ]
    iex> Operations.ShiftRow.apply(matrix)
    [[11, 12, 13, 14],
     [22, 23, 24, 21],
     [33, 34, 31, 32],
     [44, 41, 42, 43]]
    iex> matrix |> Operations.ShiftRow.apply() |> Operations.ShiftRow.revert() == matrix
    true
  """

  def apply(rows) do
    for {row, i} <- Enum.with_index(rows) do
      rotate(row, i)
    end
  end

  def revert(rows) do
    for {row, i} <- Enum.with_index(rows) do
      rotate(row, -i)
    end
  end

  def rotate(row, i \\ 1) do
    row |> Enum.split(i) |> (fn {l, r} -> r ++ l end).()
  end
end
