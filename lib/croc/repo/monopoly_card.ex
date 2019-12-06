defmodule Croc.Repo.Games.Monopoly.Card do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Croc.Repo
  alias Croc.Sessions.Session

  schema "monopoly_cards" do
    field :name, :string, null: false
    field :payment_amount, :integer
    field :type, Ecto.Atom, null: false
    field :monopoly_type, Ecto.Atom
    field :position, :integer
    field :loan_amount, :integer
    field :buyout_cost, :integer
    field :upgrade_cost, :integer
    field :cost, :integer
    field :max_upgrade_level, :integer
    field :upgrade_level_multipliers, {:array, :float}
    field :disabled, :boolean, default: false, null: false
    field :rarity, :integer, default: 0, null: false
    field :image_url, :string
    field :is_default, :boolean, null: false

    timestamps()
  end

  def changeset(%__MODULE__{} = card, %{type: :brand} = attrs) do
    monopoly_card =
      card
      |> cast_changeset(attrs)
      |> validate_number(:payment_amount, greater_than: 0)
      |> validate_required([
        :image_url,
        :position,
        :loan_amount,
        :buyout_cost,
        :upgrade_cost,
        :is_default,
        :name,
        :payment_amount,
        :monopoly_type,
        :rarity,
        :upgrade_level_multipliers,
        :max_upgrade_level,
        :cost
      ])
  end

  def changeset(%__MODULE__{} = card, %{type: :random_event} = attrs) do
    monopoly_card =
      card
      |> cast_changeset(attrs)
      |> delete_change(:payment_amount)
      |> delete_change(:buyout_cost)
      |> delete_change(:upgrade_cost)
      |> delete_change(:cost)
      |> delete_change(:upgrade_level_multipliers)
      |> delete_change(:max_upgrade_level)
      |> delete_change(:loan_amount)
      |> validate_required([
        :image_url,
        :position,
        :is_default,
        :rarity,
        :name
      ])
  end

  def changeset(%__MODULE__{} = card, %{type: :payment} = attrs) do
    monopoly_card =
      card
      |> cast_changeset(attrs)
      |> delete_change(:buyout_cost)
      |> delete_change(:upgrade_cost)
      |> delete_change(:cost)
      |> delete_change(:upgrade_level_multipliers)
      |> delete_change(:max_upgrade_level)
      |> delete_change(:loan_amount)
      |> validate_number(:payment_amount, greater_than: 0)
      |> validate_required([
        :payment_amount,
        :position,
        :is_default,
        :rarity,
        :name
      ])
  end

  def changeset(%__MODULE__{} = card, attrs) do
    card
    |> cast_changeset(attrs)
    |> validate_required([:name])
  end

  def cast_changeset(%__MODULE__{} = card, attrs) do
    card
    |> cast(attrs, [
      :name,
      :payment_amount,
      :type,
      :monopoly_type,
      :position,
      :loan_amount,
      :buyout_cost,
      :upgrade_cost,
      :cost,
      :max_upgrade_level,
      :upgrade_level_multipliers,
      :disabled,
      :rarity,
      :image_url,
      :is_default
    ])
  end

  def create(attrs) do
    monopoly_card =
      %__MODULE__{}
      |> changeset(attrs)
      |> Repo.insert!()

    {:ok, monopoly_card}
  end

  def get_by_id(id) do
    __MODULE__
    |> Repo.get(id)
  end

  def get_default_by_positions(positions) do
    __MODULE__
    |> where([c], c.position in ^positions)
    |> Repo.all()
    |> Enum.uniq_by(fn c -> c.position end)
    |> Enum.map(fn c -> Map.from_struct(c) end)
    |> Enum.map(fn c -> struct(Croc.Games.Monopoly.Card, c) end)
  end
end
