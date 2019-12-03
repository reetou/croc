defmodule Croc.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string, null: false, unique: true
      add :email, :string, unique: true, null: false
      add :password_hash, :string
      add :confirmed_at, :utc_datetime
      add :reset_sent_at, :utc_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
