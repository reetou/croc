defmodule Croc.Repo.Migrations.CreateMonopolyEventCardsIndex do
  use Ecto.Migration

  def change do
    create index(:monopoly_event_cards, [:type])
  end
end
