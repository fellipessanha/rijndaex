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
      iex> Operations.ShiftRow.apply(matrix) |> List.flatten()
      [11, 22, 33, 44,
       21, 32, 43, 14,
       31, 42, 13, 24,
       41, 12, 23, 34]
      iex> matrix |> Operations.ShiftRow.apply() |> Operations.ShiftRow.revert() == matrix
      true
  """

  @spec apply([[non_neg_integer()]]) :: [[non_neg_integer()]]
  @doc """
  Applies the ShiftRow transformation to a 4×4 byte matrix.

  Row `i` is cyclically left-shifted by `i` positions.
  """
  def apply(block = [first | _]) when is_integer(first),
    do: block |> Enum.chunk_every(4, 4, :discard) |> apply()

  def apply(block = [first | _]) when is_list(first) do
    block
    |> transpose
    |> Enum.with_index()
    |> Enum.map(fn {row, idx} ->
      rotate(row, idx)
    end)
    |> transpose()
  end

  @spec revert([[non_neg_integer()]]) :: [[non_neg_integer()]]
  @doc """
  Applies the inverse ShiftRow transformation to a 4×4 byte matrix.

  Row `i` is cyclically right-shifted by `i` positions, undoing `apply/1`.

  ## Examples

      iex> Operations.ShiftRow.revert(
      ...> [11, 22, 33, 44,
      ...>  21, 32, 43, 14,
      ...>  31, 42, 13, 24,
      ...>  41, 12, 23, 34])
      [ [11, 12, 13, 14],
        [21, 22, 23, 24],
        [31, 32, 33, 34],
        [41, 42, 43, 44]
      ]
  """
  def revert(block = [first | _]) when is_integer(first),
    do: block |> Enum.chunk_every(4, 4, :discard) |> revert()

  def revert(block = [first | _]) when is_list(first) do
    block
    |> transpose
    |> Enum.with_index()
    |> Enum.map(fn {row, idx} ->
      rotate(row, -idx)
    end)
    |> transpose()
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

  def transpose(matrix), do: matrix |> Enum.zip() |> Enum.map(&Tuple.to_list/1)
end
