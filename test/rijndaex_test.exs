defmodule RijndaexTest do
  use ExUnit.Case
  doctest Rijndaex
  doctest CypherInput
  doctest KeyExpansion

  describe "test full key expansion" do
    @sample_key <<0x54, 0x68, 0x61, 0x74, 0x73, 0x20, 0x6D, 0x79, 0x20, 0x4B, 0x75, 0x6E, 0x67,
                  0x20, 0x46, 0x75>>

    @sample_input <<0x54, 0x77, 0x6F, 0x20, 0x4F, 0x6E, 0x65, 0x20, 0x4E, 0x69, 0x6E, 0x65, 0x20,
                    0x54, 0x77, 0x6F>>

    test "all zeros" do
      ans =
        [
          [98, 99, 99, 99, 98, 99, 99, 99, 98, 99, 99, 99, 98, 99, 99, 99],
          [155, 152, 152, 201, 249, 251, 251, 170, 155, 152, 152, 201, 249, 251, 251, 170],
          [144, 151, 52, 80, 105, 108, 207, 250, 242, 244, 87, 51, 11, 15, 172, 153],
          [238, 6, 218, 123, 135, 106, 21, 129, 117, 158, 66, 178, 126, 145, 238, 43],
          [127, 46, 43, 136, 248, 68, 62, 9, 141, 218, 124, 187, 243, 75, 146, 144],
          [236, 97, 75, 133, 20, 37, 117, 140, 153, 255, 9, 55, 106, 180, 155, 167],
          [33, 117, 23, 135, 53, 80, 98, 11, 172, 175, 107, 60, 198, 27, 240, 155],
          [14, 249, 3, 51, 59, 169, 97, 56, 151, 6, 10, 4, 81, 29, 250, 159],
          [177, 212, 216, 226, 138, 125, 185, 218, 29, 123, 179, 222, 76, 102, 73, 65],
          [180, 239, 91, 203, 62, 146, 226, 17, 35, 233, 81, 207, 111, 143, 24, 142]
        ]
        |> Enum.map(&KeyExpansion.key_to_words/1)

      assert KeyExpansion.expand_key(for _ <- 1..16, into: <<>>, do: <<0>>) == ans
    end

    test "all 0xFF" do
      ans =
        [
          [232, 233, 233, 233, 23, 22, 22, 22, 232, 233, 233, 233, 23, 22, 22, 22],
          [173, 174, 174, 25, 186, 184, 184, 15, 82, 81, 81, 230, 69, 71, 71, 240],
          [9, 14, 34, 119, 179, 182, 154, 120, 225, 231, 203, 158, 164, 160, 140, 110],
          [225, 106, 189, 62, 82, 220, 39, 70, 179, 59, 236, 216, 23, 155, 96, 182],
          [229, 186, 243, 206, 183, 102, 212, 136, 4, 93, 56, 80, 19, 198, 88, 230],
          [113, 208, 125, 179, 198, 182, 169, 59, 194, 235, 145, 107, 209, 45, 201, 141],
          [233, 13, 32, 141, 47, 187, 137, 182, 237, 80, 24, 221, 60, 125, 209, 80],
          [150, 51, 115, 102, 185, 136, 250, 208, 84, 216, 226, 13, 104, 165, 51, 93],
          [139, 240, 63, 35, 50, 120, 197, 243, 102, 160, 39, 254, 14, 5, 20, 163],
          [214, 10, 53, 136, 228, 114, 240, 123, 130, 210, 215, 133, 140, 215, 195, 38]
        ]
        |> Enum.map(&KeyExpansion.key_to_words/1)

      assert KeyExpansion.expand_key(for _ <- 1..16, into: <<>>, do: <<0xFF>>) == ans
    end
  end

  test "apply |> revert returns input" do
    key = @sample_key
    input = @sample_input

    cyphered = Rijndaex.cypher_blocks(key, input)
    assert Rijndaex.uncypher_blocks(key, cyphered) === input
  end

  test "async with same key returns the same as naive parser" do
    key = @sample_key
    input = @sample_input

    cyphered_reference = Rijndaex.cypher_blocks(key, input, :naive)

    assert Rijndaex.cypher_blocks(key, input, :ecb) == cyphered_reference
  end

  test "parallel uncypher returns original value" do
    key = @sample_key
    input = @sample_input

    cyphered_reference = Rijndaex.cypher_blocks(key, input, :naive)

    assert Rijndaex.uncypher_blocks(key, cyphered_reference, :ecb) == input
  end

  test "CBC cyphers and decyphers multiblock input" do
    key = @sample_key
    input = @sample_input <> @sample_key

    cyphered = Rijndaex.cypher_blocks(key, input, :cbc)
    assert cyphered != input
    assert Rijndaex.uncypher_blocks(key, cyphered, :cbc) == input
  end
end
