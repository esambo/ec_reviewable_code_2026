defmodule Wordl.Games do
  @moduledoc """
  Puzzles, plays, and PubSub updates for the shared Wordl board.
  """

  import Ecto.Query

  alias Wordl.Dictionary
  alias Wordl.Repo
  alias Wordl.Games.Play
  alias Wordl.Games.Puzzle

  @topic "games"

  def subscribe do
    Phoenix.PubSub.subscribe(Wordl.PubSub, @topic)
  end

  def current_puzzle do
    Puzzle
    |> order_by(desc: :id)
    |> limit(1)
    |> preload(:plays)
    |> Repo.one()
  end

  def get_puzzle!(id) do
    Puzzle
    |> preload(:plays)
    |> Repo.get!(id)
  end

  def get_play!(id) do
    Play
    |> preload(:puzzle)
    |> Repo.get!(id)
  end

  def list_past_puzzles do
    current_id =
      case current_puzzle() do
        nil -> nil
        puzzle -> puzzle.id
      end

    Puzzle
    |> then(fn query ->
      if current_id, do: where(query, [p], p.id != ^current_id), else: query
    end)
    |> order_by(desc: :id)
    |> preload(:plays)
    |> Repo.all()
  end

  def generate_puzzle do
    used =
      Puzzle
      |> select([p], p.secret)
      |> Repo.all()

    %Puzzle{}
    |> Puzzle.changeset(%{secret: Dictionary.random_secret(used)})
    |> Repo.insert()
    |> tap(&broadcast_ok/1)
  end

  def start_play(puzzle, player_name) do
    name = String.trim(player_name || "")

    cond do
      name == "" ->
        {:error, :blank_name}

      true ->
        case Repo.get_by(Play, puzzle_id: puzzle.id, player_name: name) do
          %Play{} = play ->
            {:ok, Repo.preload(play, :puzzle)}

          nil ->
            %Play{}
            |> Play.changeset(%{
              player_name: name,
              puzzle_id: puzzle.id,
              guesses: [],
              status: "playing"
            })
            |> Repo.insert()
            |> case do
              {:ok, play} ->
                play = Repo.preload(play, :puzzle)
                broadcast({:play_updated, play})
                {:ok, play}

              {:error, changeset} ->
                {:error, changeset}
            end
        end
    end
  end

  def submit_guess(%Play{status: status}, _guess) when status != "playing" do
    {:error, :game_over}
  end

  def submit_guess(%Play{} = play, guess) do
    word = guess |> String.trim() |> String.downcase()

    cond do
      byte_size(word) != 5 ->
        {:error, :invalid_length}

      not Dictionary.valid_guess?(word) ->
        {:error, :not_in_dictionary}

      word in play.guesses ->
        {:error, :already_guessed}

      true ->
        play = Repo.preload(play, :puzzle)
        guesses = play.guesses ++ [word]
        status = status_after(guesses, play.puzzle.secret)

        play
        |> Play.changeset(%{guesses: guesses, status: status})
        |> Repo.update()
        |> case do
          {:ok, updated} ->
            updated = Repo.preload(updated, :puzzle, force: true)
            broadcast({:play_updated, updated})
            {:ok, updated}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def completed_plays(%Puzzle{plays: plays}) do
    plays
    |> Enum.filter(&(&1.status in ["won", "lost"]))
    |> Enum.sort_by(&{Play.score(&1), &1.player_name})
  end

  def active_plays(%Puzzle{plays: plays}) do
    plays
    |> Enum.filter(&(&1.status == "playing"))
    |> Enum.sort_by(& &1.player_name)
  end

  defp status_after(guesses, secret) do
    cond do
      List.last(guesses) == secret -> "won"
      length(guesses) >= Play.max_guesses() -> "lost"
      true -> "playing"
    end
  end

  defp broadcast_ok({:ok, puzzle}) do
    broadcast({:puzzle_created, puzzle})
    {:ok, puzzle}
  end

  defp broadcast_ok(other), do: other

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Wordl.PubSub, @topic, message)
  end
end
