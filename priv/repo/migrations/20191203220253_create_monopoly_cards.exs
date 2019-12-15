defmodule Croc.Repo.Migrations.MonopolyCards do
  use Ecto.Migration

  def change do
    create table(:monopoly_cards) do
      add :name, :string, null: false
      add :payment_amount, :integer
      add :type, :string, null: false
      add :monopoly_type, :string
      add :position, :integer
      add :loan_amount, :integer
      add :buyout_cost, :integer
      add :upgrade_cost, :integer
      add :cost, :integer
      add :max_upgrade_level, :integer
      add :upgrade_level_multipliers, {:array, :float}
      add :disabled, :boolean, default: false, null: false
      add :rarity, :integer, default: 0, null: false
      add :image_url, :string
      add :is_default, :boolean, null: false
      timestamps()
    end

    create index(:monopoly_cards, [:id])
  end
end
