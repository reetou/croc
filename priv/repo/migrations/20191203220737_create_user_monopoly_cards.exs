defmodule Croc.Repo.Migrations.CreateUserMonopolyCards do
  use Ecto.Migration

  def change do
    create table(:user_monopoly_cards) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :equipped_position, :integer
      add :monopoly_card_id, references(:monopoly_cards, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:user_monopoly_cards, [:user_id])
    create index(:user_monopoly_cards, [:monopoly_card_id])
    create index(:user_monopoly_cards, [:user_id, :equipped_position])
  end
end
