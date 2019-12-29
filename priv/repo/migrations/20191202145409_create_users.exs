defmodule Croc.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :first_name, :string
      add :last_name, :string
      add :vk_id, :integer
      add :email, :string
      add :image_url, :text
      add :password_hash, :string
      add :confirmed_at, :utc_datetime
      add :reset_sent_at, :utc_datetime
      add :is_admin, :boolean

      timestamps()
    end

    create unique_index(:users, [:email, :vk_id])
    create unique_index(:users, [:email])
    create unique_index(:users, [:vk_id])
  end
end
