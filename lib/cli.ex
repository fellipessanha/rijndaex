defmodule Rijndaex.CLI do
  def main(args \\ ["no options here"]) do
    {args, _, _} =
      OptionParser.parse(args,
        switches: [
          mode: :string,
          key: :string,
          key_file: :string,
          input: :string,
          input_file: :string,
          strategy: :string,
          key_size: :integer,
          output_file: :string
        ]
      )

    mode = parse_mode(args)
    input = parse_input!(args)
    key = parse_key(args)
    strategy = parse_strategy(args)
    output_path = parse_output_path(args)

    output_content =
      case mode do
        :cypher -> Rijndaex.cypher_blocks(key, input, strategy)
        :uncypher -> Rijndaex.uncypher_blocks(key, input, strategy)
      end

    IO.puts("Writing #{mode |> Atom.to_string()}ed output into #{inspect(output_path)}")

    File.write!(output_path, output_content)
  end

  def parse_input!(args) do
    cond do
      Keyword.has_key?(args, :input) ->
        Keyword.get(args, :input)

      Keyword.has_key?(args, :input_file) ->
        Keyword.get(args, :input_file) |> File.read!()

      true ->
        raise "no input registered! add --input or --input-file option"
    end
  end

  def parse_key(args) do
    cond do
      Keyword.has_key?(args, :key) ->
        Keyword.get(args, :key)

      Keyword.has_key?(args, :key_file) ->
        Keyword.get(args, :key) |> File.read!()

      Keyword.has_key?(args, :key_size) ->
        Keyword.get(args, :key_size) |> generate_random_key()

      true ->
        generate_random_key(128)
    end
  end

  defp parse_strategy(args) when is_list(args) do
    Keyword.get(args, :strategy, "ecb") |> parse_strategy()
  end

  defp parse_strategy("ecb"), do: :ecb
  defp parse_strategy("cbc"), do: :cbc
  defp parse_strategy("naive"), do: :naive

  defp parse_mode(args) when is_list(args),
    do: args |> Keyword.get(:mode, "cypher") |> parse_mode()

  defp parse_mode("cypher"), do: :cypher
  defp parse_mode("uncypher"), do: :uncypher

  defp parse_output_path(args), do: Keyword.get(args, :output_file, "output.txt")

  defp generate_random_key(bitsize) do
    for _ <- 1..div(bitsize, 8), into: <<>>, do: <<:rand.uniform(bitsize - 1)>>
  end
end
