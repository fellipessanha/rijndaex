defmodule Utils do
  def as_matrix(input, row_size \\ 4)

  def as_matrix(input, row_size) when is_binary(input) do
    input |> :binary.bin_to_list() |> as_matrix(row_size)
  end

  def as_matrix(input, row_size) when is_list(input) do
    Enum.chunk_every(input, row_size, row_size, :discard)
  end
end
