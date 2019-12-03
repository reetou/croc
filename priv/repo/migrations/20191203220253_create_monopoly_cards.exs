defmodule Croc.Repo.Migrations.MonopolyCards do
  use Ecto.Migration

  def change do
    create table(:monopoly_cards) do
      add :name, :string, null: false
      add :payment_amount, :integer, null: false
      add :type, :integer, null: false
      add :monopoly_type, :integer
      add :position, :integer, null: false
      add :loan_amount, :integer, null: false
      add :buyout_amount, :integer, null: false
      add :cost, :integer, null: false
      add :max_upgrade_level, :integer, null: false
      add :upgrade_level_payment_amounts, {:array, :integer}, null: false
      add :disabled, :boolean, default: false, null: false
      add :rarity, :integer, default: 0, null: false
      add :image_url, :string
      timestamps()
    end

    create index(:monopoly_cards, [:id])
  end
end
