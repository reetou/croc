defmodule Croc.Repo.Games.Monopoly.UserCard do
  use Ecto.Schema

  import Ecto.Changeset

  alias Croc.Repo
  alias Croc.Sessions.Session

  @derive {Jason.Encoder, except: [:__meta__, :user]}
  schema "user_monopoly_cards" do
    field :equipped_position, :integer
    belongs_to :monopoly_card, Croc.Repo.Games.Monopoly.Card, foreign_key: :monopoly_card_id
    belongs_to :user, Croc.Accounts.User, foreign_key: :user_id

    timestamps()
  end

  def changeset(module, attrs) do
    module
    |> cast(attrs, [:monopoly_card_id, :user_id, :equipped_position])
    |> foreign_key_constraint(:monopoly_card_id)
    |> foreign_key_constraint(:user_id)
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
    |> Repo.get_by!(id: id)
  end

  def add_to_user(user_id, card_id, position) do
    create(%{ user_id: user_id, monopoly_card_id: card_id, equipped_position: position })
  end
end
