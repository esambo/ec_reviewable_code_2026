defmodule Wordl.Games.Play do
  use Ecto.Schema
  import Ecto.Changeset

  alias Wordl.Games.Puzzle

  @max_guesses 6
  @statuses ~w(playing won lost)

  schema "plays" do
    field :player_name, :string
    field :guesses, {:array, :string}, default: []
    field :status, :string, default: "playing"
    belongs_to :puzzle, Puzzle

    timestamps(type: :utc_datetime)
  end

  def max_guesses, do: @max_guesses

  def changeset(play, attrs) do
    play
    |> cast(attrs, [:player_name, :guesses, :status, :puzzle_id])
    |> validate_required([:player_name, :puzzle_id])
    |> update_change(:player_name, &String.trim/1)
    |> validate_length(:player_name, min: 1, max: 40)
    |> validate_inclusion(:status, @statuses)
    |> unique_constraint([:puzzle_id, :player_name])
  end

  def guess_count(%__MODULE__{guesses: guesses}), do: length(guesses)

  def score(%__MODULE__{status: "won", guesses: guesses}), do: length(guesses)
  def score(%__MODULE__{status: "lost"}), do: @max_guesses + 1
  def score(%__MODULE__{}), do: nil
end
