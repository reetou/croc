defmodule Croc.Repo.Migrations.AddUsersExp do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :exp, :integer, null: false, default: 0
    end
  end
end
