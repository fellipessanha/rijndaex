defmodule Operations do
  @moduledoc """
  Shared primitives used across all AES cipher steps.

  `add/2` is the GF(2⁸) addition (XOR) used by `KeyExpansion`, `MixColumns`,
  `ShiftRow`, and the top-level `Rijndaex` cipher.
  """

  def add(left, right) when is_list(left) and is_list(right) do
    Enum.map(Enum.zip(left, right), &add/1)
  end

  def add(left, right), do: Bitwise.bxor(left, right)
  def add({left, right}), do: add(left, right)
end
