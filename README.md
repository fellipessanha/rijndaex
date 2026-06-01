# Rijndaex

Pure-Elixir implementation of the Rijndael (AES) cipher, written as an exercise for an Intro to Cryptography class taught by Luis Kowada at Universidade Federal Fluminense.

## Features

- AES block encryption and decryption
- Multiple block cipher strategies: `:naive`, `:ecb`, `:cbc` (more planned)
- CLI for encrypting/decrypting files from the command line

## Block cipher strategies

| Strategy | Description |
|----------|-------------|
| `:naive`  | Single 16-byte block, no chaining. Useful for testing. |
| `:ecb`    | Electronic Codebook — blocks encrypted independently. Simple but does not hide repeated plaintext patterns. |
| `:cbc`    | Cipher Block Chaining — each block is XOR-ed with the previous ciphertext block before encryption, hiding repetition. |

More strategies (e.g. CTR, GCM) are planned for future releases.

## Usage

### Key requirements

The key **must** be a binary of exactly **128, 192, or 256 bits** (16, 24, or 32 bytes).
Passing any other size raises a `MatchError` at runtime.

| Key size | Bytes | AES variant | Rounds |
|----------|-------|-------------|--------|
| 128 bits | 16    | AES-128     | 10     |
| 192 bits | 24    | AES-192     | 12     |
| 256 bits | 32    | AES-256     | 14     |

```elixir
# Valid 128-bit key (exactly 16 bytes)
key   = <<0x54, 0x68, 0x61, 0x74, 0x73, 0x20, 0x6D, 0x79,
          0x20, 0x4B, 0x75, 0x6E, 0x67, 0x20, 0x46, 0x75>>
input = <<0x54, 0x77, 0x6F, 0x20, 0x4F, 0x6E, 0x65, 0x20,
          0x4E, 0x69, 0x6E, 0x65, 0x20, 0x54, 0x77, 0x6F>>

# Encrypt (defaults to :ecb)
ciphertext = Rijndaex.cypher_blocks(key, input)

# Encrypt with CBC
ciphertext = Rijndaex.cypher_blocks(key, input, :cbc)

# Decrypt
plaintext = Rijndaex.uncypher_blocks(key, ciphertext, :ecb)

# Invalid key — raises MatchError at runtime
Rijndaex.cypher_blocks(<<1, 2, 3>>, input)
# ** (MatchError) no match of right hand side value: {:error, "Invalid key size: '24'. Valid options are [128, 192, 256]"}
```

## CLI

The `rijndaex` escript exposes encryption and decryption from the command line.

### Build

```sh
mix escript.build
```

### Options

Run `./rijndaex --help` to print usage information directly from the binary.

| Flag | Description |
|------|-------------|
| `--mode`        | `cypher` (default) or `uncypher` |
| `--key`         | Encryption key as a raw string — must be 16, 24, or 32 bytes (AES-128/192/256) |
| `--key-file`    | Path to a file containing the raw key bytes |
| `--key-size`    | Generate a random key of this bit size: `128`, `192`, or `256` |
| `--input`       | Plaintext/ciphertext as a string |
| `--input-file`  | Path to a file to encrypt or decrypt |
| `--strategy`    | `ecb` (default), `cbc`, or `naive` |
| `--output-file` | Destination file for the result (default: `output.txt`) |
| `--help`        | Print usage information and exit |

If no key option is provided, a random 128-bit key is generated automatically.

### Examples

```sh
# Encrypt a file with ECB (default strategy)
./rijndaex --input-file plain.txt --key "mysecretkey12345" --output-file cipher.bin

# Decrypt with CBC
./rijndaex --mode uncypher --strategy cbc --input-file cipher.bin --key "mysecretkey12345" --output-file plain.txt

# Encrypt with a randomly generated 128-bit key
./rijndaex --input "Hello, World!" --key-size 128
```

## References

- https://blog.0x7d0.dev/education/how-aes-is-implemented/
- https://www.samiam.org/key-schedule.html — especially useful for examples and test cases
