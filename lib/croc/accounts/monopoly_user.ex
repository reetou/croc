defmodule Croc.Accounts.MonopolyUser do
  alias Croc.Accounts
  alias Croc.Accounts.User
  alias Croc.Repo
  import Ecto.Query

  defstruct [
    :name,
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

  def get_name(player_id) do
    user = Accounts.get_user(player_id)
    default_name = "Игрок #{player_id}"
    name =
      cond do
        user == nil -> default_name
        is_binary(user.first_name) and is_binary(user.last_name) -> user.first_name <> " " <> user.last_name
        is_binary(user.username) -> user.username
        true -> default_name
      end
    %__MODULE__{
      name: name
    }
  end
end
