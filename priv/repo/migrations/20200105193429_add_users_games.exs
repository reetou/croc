defmodule Croc.Repo.Migrations.AddUsersGames do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :games, :integer, null: false, default: 0
      add :games_won, :integer, null: false, default: 0
    end
  end
end
