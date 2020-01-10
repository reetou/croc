defmodule Croc.Accounts.MonopolyUser do
  alias Croc.Accounts
  alias Croc.Accounts.User
  alias Croc.Repo
  import Ecto.Query

  defstruct [
    :name,
    :image_url
  ]

  def get_event_cards(player_id) do
    Accounts.get_user!(player_id)
    |> Repo.preload(:monopoly_event_cards)
    |> Map.fetch!(:user_monopoly_event_cards)
  end

  def update_user_stats(id, winner \\ false) do
    default_inc = [games: 1]
    inc = if winner, do: default_inc ++ [games_won: 1], else: default_inc
    User
    |> where([u], u.id == ^id)
    |> update([u], inc: ^inc)
    |> Repo.update_all([])
  end

  def get_player(player_id) do
    user = Accounts.get_user(player_id)
    default_name = "Игрок #{player_id}"
    image_url =
      case user do
        nil -> nil
        user -> user.image_url
      end
    name =
      cond do
        user == nil -> default_name
        is_binary(user.first_name) -> user.first_name
        is_binary(user.username) -> user.username
        true -> default_name
      end
    %__MODULE__{
      name: name,
      image_url: image_url
    }
  end
end
