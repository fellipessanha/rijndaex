defmodule Operations.ShiftRow do
  @moduledoc """
  Implements the ShiftRow step of the AES cipher.

  Cyclically shifts row `i` of a 4×4 byte matrix left by `i` positions:
  - Row 0: no shift
  - Row 1: left by 1
  - Row 2: left by 2
  - Row 3: left by 3

  ## Examples

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

  @spec apply([[non_neg_integer()]]) :: [[non_neg_integer()]]
  @doc """
  Applies the ShiftRow transformation to a 4×4 byte matrix.

  Row `i` is cyclically left-shifted by `i` positions.

  ## Examples

      iex> Operations.ShiftRow.apply([[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]])
      [[1, 2, 3, 4], [6, 7, 8, 5], [11, 12, 9, 10], [16, 13, 14, 15]]
  """
  def apply(rows) do
    for {row, i} <- Enum.with_index(rows) do
      rotate(row, i)
    end
  end

  @spec revert([[non_neg_integer()]]) :: [[non_neg_integer()]]
  @doc """
  Applies the inverse ShiftRow transformation to a 4×4 byte matrix.

  Row `i` is cyclically right-shifted by `i` positions, undoing `apply/1`.

  ## Examples

      iex> Operations.ShiftRow.revert([[1, 2, 3, 4], [6, 7, 8, 5], [11, 12, 9, 10], [16, 13, 14, 15]])
      [[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11, 12], [13, 14, 15, 16]]
  """
  def revert(rows) do
    for {row, i} <- Enum.with_index(rows) do
      rotate(row, -i)
    end
  end

  @spec rotate([non_neg_integer()], integer()) :: [non_neg_integer()]
  @doc """
  Cyclically rotates a list by `i` positions.

  Positive `i` rotates left; negative `i` rotates right. Defaults to 1.

  ## Examples

      iex> Operations.ShiftRow.rotate([1, 2, 3, 4])
      [2, 3, 4, 1]
      iex> Operations.ShiftRow.rotate([1, 2, 3, 4], 2)
      [3, 4, 1, 2]
      iex> Operations.ShiftRow.rotate([1, 2, 3, 4], -1)
      [4, 1, 2, 3]
  """
  def rotate(row, i \\ 1) do
    row |> Enum.split(i) |> (fn {l, r} -> r ++ l end).()
  end
end
