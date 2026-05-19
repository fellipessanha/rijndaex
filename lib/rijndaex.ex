defmodule Rijndaex do
  @moduledoc """
  Pure-Elixir implementation of the Rijndael (AES) cipher.

  Provides the core building blocks of the AES algorithm:

  - `CypherInput` — validates the cipher key and pads plaintext to 16-byte block boundaries
  - `KeyExpansion` — derives per-round subkeys from the original cipher key (key schedule)
  - `Operations.SubBytes` — non-linear byte substitution via the AES S-box
  - `Operations.ShiftRow` — cyclic row permutation over the 4×4 state matrix
  - `Operations.MixColumns` — column mixing via GF(2⁸) matrix multiplication
  """

  def entrypoint(key, input) do
    parsed_input = CypherInput.new(key, input)
    expanded_key = KeyExpansion.expand_key(key)

    apply(expanded_key, parsed_input)
  end
end
