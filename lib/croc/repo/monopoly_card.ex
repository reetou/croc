defmodule Croc.Repo.Games.Monopoly.Card do

  use Ecto.Schema

  import Ecto.Changeset

  alias Croc.Repo
  alias Croc.Sessions.Session

  schema "monopoly_cards" do
    field :name, :string, null: false
    field :payment_amount, :integer, null: false
    field :type, :integer, null: false
    field :monopoly_type, :integer
    field :position, :integer, null: false
    field :loan_amount, :integer, null: false
    field :buyout_amount, :integer, null: false
    field :cost, :integer, null: false
    field :max_upgrade_level, :integer, null: false
    field :upgrade_level_payment_amounts, {:array, :integer}, null: false
    field :disabled, :boolean, default: false, null: false
    field :rarity, :integer, default: 0, null: false
    field :image_url, :string

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [
      :name,
      :payment_amount,
      :type,
      :monopoly_type,
      :position,
      :loan_amount,
      :buyout_amount,
      :cost,
      :max_upgrade_level,
      :upgrade_level_payment_amounts,
      :disabled,
      :rarity,
      :image_url
    ])
    |> validate_required([:name])
  end

  def create(attrs) do
    monopoly_card = __MODULE__
    |> changeset(attrs)
    |> Repo.insert!()
    {:ok, monopoly_card}
  end

  def get do
    __MODULE__
    |> Repo.get!
  end

  def get_by_id(id) do
    __MODULE__
    |> Repo.get_by!(id: id)
  end

end
