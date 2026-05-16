defmodule CypherInput do
  @enforce_keys [:key, :binary]
  @valid_keysizes [128, 192, 256]
  @binary_block_size 16

  @moduledoc """
  Validates key and input binary blob to be cyphered.
  Binary will be left padded with PKCS7 algorithm
  Accepts only keys with sizes #{inspect(@valid_keysizes)}
  Returns %CypherInput{} struct

  ## Examples:

    iex(9)> CypherInput.new(<<123::128>>, <<0::64>>)
    {:ok,
      %CypherInput{
        key: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 123>>,
        binary: <<0, 0, 0, 0, 0, 0, 0, 0, 8, 8, 8, 8, 8, 8, 8, 8>>,
        key_size: 128,
        rounds: 10
      }}

    iex(7)> CypherInput.new(<<123::125>>, <<0>>)
    {:error, "Invalid key size: '125'. Valid options are [128, 192, 256]"}

  """

  defstruct [:key, :binary, :key_size, :rounds]

  @doc """
  
  """
  def n_keys(128), do: 4
  def n_keys(192), do: 6
  def n_keys(256), do: 8
  def n_keys(_), do: raise("Invalid key size! the valid values are #{@valid_keysizes}")

  def n_round_keys(128), do: 10
  def n_round_keys(192), do: 12
  def n_round_keys(256), do: 14

  defp validade_keysize(key_size) when key_size in @valid_keysizes, do: :ok

  defp validade_keysize(key_size),
    do:
      {:error, "Invalid key size: \'#{key_size}\'. Valid options are #{inspect(@valid_keysizes)}"}

  defp right_pad_to_valid_binary_size(binary) do
    pad_value = rem(byte_size(binary), @binary_block_size)
    binary <> :binary.copy(<<pad_value>>, pad_value)
  end

  def new(key, binary) when is_bitstring(key) and is_binary(binary) do
    key_size = bit_size(key)

    with :ok <- validade_keysize(key_size) do
      padded_binary = right_pad_to_valid_binary_size(binary)

      {:ok,
       %__MODULE__{
         key: key,
         binary: padded_binary,
         key_size: key_size,
         rounds: n_round_keys(key_size)
       }}
    end
  end

  def new(_, _),
    do:
      {:error,
       "Arguments for #{__MODULE__}.new/2 are. bistring with valid size: #{inspect(@valid_keysizes)}, binary"}
end
