defmodule Wordl.GamesTest do
  use Wordl.DataCase, async: true

  alias Wordl.Dictionary
  alias Wordl.Games
  alias Wordl.Games.Play

  test "generate_puzzle stores a five-letter secret" do
    assert {:ok, puzzle} = Games.generate_puzzle()
    assert String.length(puzzle.secret) == 5
    assert Games.current_puzzle().id == puzzle.id
  end

  test "submit_guess colors progress and completes a win" do
    {:ok, puzzle} = Games.generate_puzzle()
    {:ok, play} = Games.start_play(puzzle, "Ada")

    assert {:error, :not_in_dictionary} = Games.submit_guess(play, "hell0")
    {:ok, play} = Games.submit_guess(play, "hello")

    miss = Enum.find(Dictionary.secrets(), &(&1 != puzzle.secret))
    {:ok, play} = Games.submit_guess(play, miss)
    assert play.status == "playing"
    assert play.guesses == ["hello", miss]

    {:ok, won} = Games.submit_guess(play, puzzle.secret)
    assert won.status == "won"
    assert Play.score(won) == 3
  end

  test "start_play reuses an existing board for the same name" do
    {:ok, puzzle} = Games.generate_puzzle()
    {:ok, first} = Games.start_play(puzzle, "Ada")
    {:ok, second} = Games.start_play(puzzle, "Ada")
    assert first.id == second.id
  end
end
