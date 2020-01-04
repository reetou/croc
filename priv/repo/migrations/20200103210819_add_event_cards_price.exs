defmodule Croc.Repo.Migrations.AddEventCardsPrice do
  use Ecto.Migration

  def change do
    alter table(:monopoly_event_cards) do
      add :price, :integer, null: false, default: 0
    end
  end
end
