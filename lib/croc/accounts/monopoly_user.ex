defmodule Croc.Accounts.MonopolyUser do
  alias Croc.Accounts
  alias Croc.Repo

  defstruct [
    :name,
  ]

  def get_event_cards(player_id) do
    Accounts.get_user!(player_id)
    |> Repo.preload(:monopoly_event_cards)
    |> Map.fetch!(:user_monopoly_event_cards)
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
