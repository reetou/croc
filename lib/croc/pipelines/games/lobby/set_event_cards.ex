defmodule Croc.Pipelines.Lobby.SetEventCards do
  alias Croc.Games.Monopoly.{
    Event,
    EventCard,
    Lobby
  }
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias CrocWeb.MonopolyChannel
  alias Croc.Accounts.MonopolyUser
  alias Croc.Accounts.User
  alias Croc.Pipelines.Games.Monopoly.Events.{
    AuctionEnded,
    AuctionBidRequest
    }
  use Opus.Pipeline

  @event_cards_limit 3

  check :in_lobby?, error_message: :not_in_lobby
  check :valid_cards_count?, error_message: :too_many_cards
  check :has_event_cards?, error_message: :no_such_user_cards
  step :set_event_cards

  def in_lobby?(%{player_id: player_id, lobby: %Lobby{} = lobby}) do
    LobbyPlayer.in_lobby?(player_id, lobby)
  end

  def valid_cards_count?(%{event_cards: event_cards}) do
    length(event_cards) <= @event_cards_limit
  end

  def has_event_cards?(%{event_cards: event_cards, player_id: player_id}) do
    user_event_cards_id =
      MonopolyUser.get_event_cards(player_id)
      |> Enum.map(fn x -> x |> Map.fetch!(:id) end)
    event_cards
    |> Enum.all?(fn c -> Enum.member?(user_event_cards_id, c.monopoly_event_card_id) end)
  end

  def set_event_cards(%{ event_cards: event_cards, player_id: player_id, lobby: lobby } = args) do
    lobby = LobbyPlayer.put(lobby, player_id, :event_cards, event_cards)
    Map.put(args, :lobby, lobby)
  end

end
