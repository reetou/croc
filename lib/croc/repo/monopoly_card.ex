defmodule Croc.Repo.Games.Monopoly.Card do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Croc.Repo
  alias Croc.Sessions.Session
  alias Croc.Repo.Games.Monopoly.{UserCard}
  alias Croc.Accounts.User

  @derive {Jason.Encoder, except: [:disabled, :__meta__, :users, :user_monopoly_cards]}
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

    has_many :user_monopoly_cards, UserCard, foreign_key: :monopoly_card_id
    has_many :users, through: [:user_monopoly_cards, :user]

    timestamps()
  end

  def types, do: [
    :brand,
    :random_event,
    :start,
    :prison,
    :jail_cell,
    :payment,
    :teleport
  ]

  def monopoly_types, do: [
    :perfume,
    :clothing,
    :cars,
    :games,
    :fastfood,
    :hotels,
    :phones,
    :social_networks,
    :drinks,
    :airports
  ]

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

  def update!(%__MODULE__{} = card, attrs) do
    IO.inspect(attrs, label: "Attrs at update")
    card
    |> changeset(attrs)
    |> Repo.update!()
  end

  def get_default_by_positions(positions) do
    __MODULE__
    |> where([c], c.position in ^positions)
    |> Repo.all()
    |> Enum.uniq_by(fn c -> c.position end)
    |> Enum.map(fn c -> Map.put(c, :raw_payment_amount, c.payment_amount) end)
    |> Enum.map(fn c -> Map.from_struct(c) end)
    |> Enum.map(fn c -> struct(Croc.Games.Monopoly.Card, c) end)
  end

  def get_all() do
    __MODULE__
    |> Repo.all()
    |> Enum.map(fn c -> Map.from_struct(c) end)
  end

  def changeset_update(%__MODULE__{} = card, attrs) do
    card
    |> cast(attrs, [
      :name,
      :type,
      :monopoly_type,
      :image_url,
      :upgrade_level_multipliers,
      :max_upgrade_level,
      :rarity,
      :cost,
      :buyout_cost,
      :upgrade_cost,
      :loan_amount,
      :position,
      :payment_amount,
      :disabled,
      :is_default
    ])
  end

end
