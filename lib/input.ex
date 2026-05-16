defmodule CypherInput do
  @enforce_keys [:key, :binary]
  @valid_keysizes [128, 192, 256]
  @binary_block_size 16

  @moduledoc """
  Validates key and input binary blob to be ciphered.

  The binary is right-padded to the next 16-byte boundary using PKCS7.
  Accepts only keys with sizes #{inspect(@valid_keysizes)} bits.

  ## Examples

      iex> {:ok, input} = CypherInput.new(<<0::128>>, <<0::64>>)
      iex> input.key_size
      128
      iex> input.rounds
      10
      iex> byte_size(input.binary)
      16

      iex> CypherInput.new(<<123::125>>, <<0>>)
      {:error, "Invalid key size: '125'. Valid options are [128, 192, 256]"}

  """

  @type t() :: %__MODULE__{
          key: bitstring(),
          binary: binary(),
          key_size: 128 | 192 | 256,
          rounds: 10 | 12 | 14
        }

  defstruct [:key, :binary, :key_size, :rounds]

  @spec n_keys(128 | 192 | 256) :: 4 | 6 | 8
  @doc """
  Returns the number of 32-bit key words for the given key size in bits.

  AES uses 4 words for 128-bit keys, 6 for 192-bit keys, and 8 for 256-bit keys.

  ## Examples

      iex> CypherInput.n_keys(128)
      4
      iex> CypherInput.n_keys(192)
      6
      iex> CypherInput.n_keys(256)
      8
  """
  def n_keys(128), do: 4
  def n_keys(192), do: 6
  def n_keys(256), do: 8
  def n_keys(_), do: raise("Invalid key size! the valid values are #{@valid_keysizes}")

  @spec n_round_keys(128 | 192 | 256) :: 10 | 12 | 14
  @doc """
  Returns the number of encryption rounds for the given key size in bits.

  AES-128 uses 10 rounds, AES-192 uses 12 rounds, AES-256 uses 14 rounds.

  ## Examples

      iex> CypherInput.n_round_keys(128)
      10
      iex> CypherInput.n_round_keys(192)
      12
      iex> CypherInput.n_round_keys(256)
      14
  """
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

  @spec new(bitstring(), binary()) :: {:ok, t()} | {:error, String.t()}
  @doc """
  Creates a validated `CypherInput` struct from a cipher key and plaintext binary.

  Validates that `key` is exactly 128, 192, or 256 bits. Right-pads `binary`
  to the next 16-byte boundary using PKCS7.

  ## Examples

      iex> {:ok, input} = CypherInput.new(<<0::128>>, "hello")
      iex> input.key_size
      128
      iex> byte_size(input.binary)
      10

      iex> CypherInput.new(<<0::100>>, "hello")
      {:error, "Invalid key size: '100'. Valid options are [128, 192, 256]"}
  """
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
