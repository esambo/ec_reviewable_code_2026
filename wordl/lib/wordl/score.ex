defmodule Wordl.Score do
  @moduledoc """
  Colors a guess the way Wordle does: green for exact matches, yellow for
  letters that still remain in the secret, gray otherwise.
  """

  @type color :: :green | :yellow | :gray
  @type tile :: {String.t(), color()}

  @spec color(String.t(), String.t()) :: [tile()]
  def color(guess, secret)
      when is_binary(guess) and is_binary(secret) and
             byte_size(guess) == 5 and byte_size(secret) == 5 do
    guess_chars = String.graphemes(String.upcase(guess))
    secret_chars = String.graphemes(String.upcase(secret))

    remaining =
      secret_chars
      |> Enum.with_index()
      |> Enum.reduce(%{}, fn {char, index}, acc ->
        if Enum.at(guess_chars, index) == char do
          acc
        else
          Map.update(acc, char, 1, &(&1 + 1))
        end
      end)

    {tiles, _} =
      guess_chars
      |> Enum.with_index()
      |> Enum.map_reduce(remaining, fn {char, index}, leftover ->
        cond do
          Enum.at(secret_chars, index) == char ->
            {{char, :green}, leftover}

          Map.get(leftover, char, 0) > 0 ->
            {{char, :yellow}, Map.update!(leftover, char, &(&1 - 1))}

          true ->
            {{char, :gray}, leftover}
        end
      end)

    tiles
  end
end
