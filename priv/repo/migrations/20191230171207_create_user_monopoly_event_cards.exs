defmodule Croc.Repo.Migrations.CreateUserMonopolyEventCards do
  use Ecto.Migration

  def change do
    create table(:user_monopoly_event_cards) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :monopoly_event_card_id, references(:monopoly_event_cards, on_delete: :delete_all, on_update: :update_all), null: false

      timestamps()
    end
  end
end
