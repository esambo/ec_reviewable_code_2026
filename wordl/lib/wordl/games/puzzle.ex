defmodule Wordl.Games.Puzzle do
  use Ecto.Schema
  import Ecto.Changeset

  alias Wordl.Games.Play

  schema "puzzles" do
    field :secret, :string
    has_many :plays, Play

    timestamps(type: :utc_datetime)
  end

  def changeset(puzzle, attrs) do
    puzzle
    |> cast(attrs, [:secret])
    |> validate_required([:secret])
    |> update_change(:secret, &String.downcase/1)
    |> validate_length(:secret, is: 5)
    |> validate_format(:secret, ~r/^[a-z]{5}$/)
  end
end
