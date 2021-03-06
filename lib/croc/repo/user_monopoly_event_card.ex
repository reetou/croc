defmodule Croc.Repo.Games.Monopoly.UserEventCard do
  use Ecto.Schema

  import Ecto.Changeset

  alias Croc.Repo
  alias Croc.Repo.Games.Monopoly.EventCard
  alias Croc.Accounts.User

  @derive {Jason.Encoder, except: [:__meta__, :user]}
  schema "user_monopoly_event_cards" do
    belongs_to :monopoly_event_card, EventCard, foreign_key: :monopoly_event_card_id
    belongs_to :user, User, foreign_key: :user_id

    timestamps()
  end

  defp from_parent(%EventCard{id: id} = card) when id != nil do
    changeset(%{
      monopoly_event_card_id: id
    })
  end

  def cast_from_parent(cards) when is_list(cards) do
    cards
    |> Enum.map(&from_parent/1)
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:monopoly_event_card_id, :user_id])
    |> foreign_key_constraint(:monopoly_event_card_id)
    |> foreign_key_constraint(:user_id)
  end

  def create(attrs) do
    event_card =
      %__MODULE__{}
      |> changeset(attrs)
      |> Repo.insert!()

    {:ok, event_card}
  end

  def get_by_id(id) do
    __MODULE__
    |> Repo.get_by!(id: id)
  end
end
