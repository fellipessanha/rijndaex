defmodule Rijndaex.Operations.ShiftRow do
  @moduledoc """
  Shifts the ith row by i elements.

  Supposed to be used in Rijndael in 4x4 byte matrixes.

  The example islustrates the effects:

  Example:

    iex> matrix = [
    ...>   [11, 12, 13,],
    ...>   [21, 22, 23,],
    ...>   [31, 32, 33]
    ...> ]
    iex> Rijndaex.Operations.ShiftRow.apply(matrix)
    [[11, 12, 13], [22, 23, 21], [33, 31, 32]]
    iex> matrix |> Rijndaex.Operations.ShiftRow.apply() |> Rijndaex.Operations.ShiftRow.revert() == matrix
    true
  """

  def apply(rows) do
    for {row, i} <- Enum.with_index(rows) do
      row |> Enum.split(i) |> (fn {l, r} -> r ++ l end).()
    end
  end

  def revert(rows) do
    for {row, i} <- Enum.with_index(rows) do
      row |> Enum.split(-i) |> (fn {l, r} -> r ++ l end).()
    end
  end
end
