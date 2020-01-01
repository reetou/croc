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
  step :set_actual_user_event_cards
  check :has_event_cards?, error_message: :no_such_user_cards
  step :set_event_cards

  def in_lobby?(%{player_id: player_id, lobby: %Lobby{} = lobby}) do
    LobbyPlayer.in_lobby?(player_id, lobby)
  end

  def valid_cards_count?(%{event_cards: event_cards}) do
    length(event_cards) <= @event_cards_limit
  end

  def set_actual_user_event_cards(%{ player_id: player_id } = args) do
    Map.put(args, :user_event_cards, MonopolyUser.get_event_cards(player_id))
  end

  def has_event_cards?(%{event_cards: event_cards, user_event_cards: user_event_cards, player_id: player_id}) do
    user_event_cards_id =
      user_event_cards
      |> Enum.map(fn x ->
        x
        |> Map.fetch!(:id)
      end)
    event_cards
    |> Enum.all?(fn c -> Enum.member?(user_event_cards_id, c.id) end)
  end

  def set_event_cards(%{ event_cards: event_cards, player_id: player_id, lobby: lobby, user_event_cards: user_event_cards } = args) do
    event_cards_ids = Enum.map(event_cards, fn c -> c.id end)
    lobby = LobbyPlayer.put(lobby, player_id, :event_cards, user_event_cards |> Enum.filter(fn c -> c.id in event_cards_ids end))
    Map.put(args, :lobby, lobby)
  end

end
