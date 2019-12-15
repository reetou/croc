defmodule Croc.Pipelines.Games.Monopoly.AuctionReject do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Events.{
    AuctionEnded,
    AuctionRequest
  }
  require Logger
  use Opus.Pipeline

  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  step :set_event_type
  check :has_event?,  with: &Event.has_by_type?/1, error_message: :no_auction_event
  step :add_position
  check :card_exists?, error_message: :no_card
  step :add_card
  step :add_player
  step :add_event
  step :set_amount
  check :no_owner?, error_message: :card_has_owner
  check :card_type_valid?, error_message: :invalid_card_type
  step :remove_event, with: &Event.remove_player_event/1
  step :set_new_auction_members
  link AuctionEnded, if: :no_members?
  step :overwrite_player_id, if: :last_member_is_bidder?
  link AuctionEnded, if: :last_member_is_bidder?
  link AuctionRequest, if: :has_members?

  def has_members?(%{ members: members, event: event }) do
    members != [event.last_bidder] and length(members) > 0
  end

  def add_event(%{ game: game, player_id: player_id, event_id: event_id } = args) do
    player = Player.get(game, player_id)
    %Event{} = event = Enum.find(player.events, fn e -> e.event_id == event_id end)
    Map.put(args, :event, event)
  end

  def change_player_turn(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Map.put(game, :player_turn, player_id))
  end

  def add_auction_event(%{
    game: game,
    player_id: player_id,
    amount: amount,
    card: card,
    event: event,
    members: members
  } = args) do
    new_event = Event.auction(amount, "#{player_id} Думает о поднятии цены", card.position, event.starter, event.last_bidder, members)
    Map.put(args, :game, Event.add_player_event(game, player_id, new_event))
  end

  def set_event_type(args) do
    Map.put(args, :type, :auction)
  end

  def no_members?(%{ members: members }) do
    length(members) == 0
  end

  def last_member_is_bidder?(%{ event: event, members: members }) do
    members == [event.last_bidder]
  end

  def no_other_members?(%{ game: game, player_id: player_id, event: event, members: members }) do
    members_without_me = Enum.filter(members, fn id -> id != player_id end)
    length(members_without_me) == 0
  end

  def overwrite_player_id(%{ game: game, player_id: player_id, event: event } = args) do
    args
    |> Map.put(:player_id, List.first(event.members))
  end

  def card_exists?(%{ game: game, position: position }) do
    card = Card.get_by_position(game, position)
    card != nil
  end

  def set_new_auction_members(%{ event: event, player_id: player_id } = args) do
    members =
      event
      |> Map.fetch!(:members)
      |> case do
          [] -> []
          members -> Enum.filter(members, fn id -> id != player_id end)
         end
    new_event = Map.put(event, :members, members)
    args
    |> Map.put(:members, members)
    |> Map.put(:event, new_event)
  end

  def add_card(%{game: game, player_id: player_id, position: position} = args) do
    %Card{} = card = Card.get_by_position(game, position)
    Map.put(args, :card, card)
  end

  def add_player(%{game: game, player_id: player_id, position: position} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    Map.put(args, :player, player)
  end

  def set_amount(%{ game: game, player_id: player_id } = args) do
    player = Player.get(game, player_id)
    amount = Enum.find(player.events, fn e -> e.type == :auction end)
             |> Map.fetch!(:amount)
    Map.put(args, :amount, amount)
  end

  def add_position(%{game: game, player_id: player_id, event_id: event_id} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    event = Enum.find(player.events, fn e -> e.event_id == event_id end)
    Map.put(args, :position, event.position)
  end

  def is_owner?(%{ card: card, player_id: player_id } = args) do
    card.owner == player_id
  end

  def no_owner?(%{ card: card }) do
    card.owner == nil
  end

  def card_type_valid?(%{ card: card }) do
    card.type == :brand
  end
end
