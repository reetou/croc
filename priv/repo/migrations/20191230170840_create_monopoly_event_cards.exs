defmodule Croc.Repo.Migrations.CreateMonopolyEventCards do
  use Ecto.Migration

  def change do
    create table(:monopoly_event_cards) do
      add :name, :string
      add :description, :string
      add :type, :string
      add :rarity, :integer, default: 0, null: false
      add :disabled, :boolean, null: false, default: false
      add :image_url, :text
    end
  end
end
