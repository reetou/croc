defmodule Croc.Repo.Games.Monopoly.EventCard do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Croc.Repo

  schema "monopoly_event_cards" do
    field :name, :string, null: false
    field :description, :string, null: false
    field :type, Ecto.Atom, null: false
    field :disabled, :boolean, default: false, null: false
    field :rarity, :integer, default: 0, null: false
    field :image_url, :string
  end

  def changeset(%__MODULE__{} = event_card, attrs) do
    event_card
    |> cast(attrs, [:name, :description, :type, :disabled, :rarity, :image_url])
    |> validate_required([
      :name,
      :description,
      :type,
      :rarity,
      :image_url,
    ])
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!()
  end

  def get_by_id(id) do
    __MODULE__
    |> Repo.get(id)
  end

  def get_all() do
    __MODULE__
    |> Repo.all()
    |> Enum.map(fn c -> Map.from_struct(c) end)
  end

end
