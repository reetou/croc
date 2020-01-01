defmodule Croc.Accounts.MonopolyUser do
  alias Croc.Accounts
  alias Croc.Repo

  def get_event_cards(player_id) do
    Accounts.get_user!(player_id)
    |> Repo.preload(:monopoly_event_cards)
    |> Map.fetch!(:user_monopoly_event_cards)
  end
end
