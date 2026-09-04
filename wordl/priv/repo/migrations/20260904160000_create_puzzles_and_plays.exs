defmodule Wordl.Repo.Migrations.CreatePuzzlesAndPlays do
  use Ecto.Migration

  def change do
    create table(:puzzles) do
      add :secret, :string, null: false, size: 5
      timestamps(type: :utc_datetime)
    end

    create table(:plays) do
      add :player_name, :string, null: false
      add :guesses, {:array, :string}, null: false, default: []
      add :status, :string, null: false, default: "playing"
      add :puzzle_id, references(:puzzles, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:plays, [:puzzle_id, :player_name])
    create index(:plays, [:puzzle_id])
  end
end
