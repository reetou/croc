defmodule Croc.Pipelines.Games.Monopoly.AuctionBid do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Pipelines.Games.Monopoly.Events.{
    AuctionEnded,
    AuctionBidRequest
  }
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
  step :set_bid_amount
  check :has_enough_money?, error_message: :not_enough_money
  step :set_members
  step :set_bidder
  step :remove_event, with: &Event.remove_player_event/1

  link AuctionBidRequest, if: :has_members?
  link AuctionEnded, unless: :has_members?

  def change_player_turn(%{ player_id: player_id, game: game } = args) do
    Map.put(args, :game, Map.put(game, :player_turn, player_id))
  end

  def has_members?(%{ members: members, event: event }) do
    members != [event.last_bidder] and length(members) > 0
  end

  def overwrite_player_id_with_next_member(%{ event: event, player_id: player_id } = args) do
    current_member_index = Enum.find_index(event.members, fn id -> id == player_id end)
    next_member_id = Enum.at(event.members, current_member_index + 1, Enum.at(event.members, 0))
    Map.put(args, :player_id, next_member_id)
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

  def set_bidder(%{ event: event, player_id: player_id, amount: amount } = args) do
    new_event = event
                |> Map.put(:last_bidder, player_id)
                |> Map.put(:amount, amount)
    Map.put(args, :event, new_event)
  end

  def no_other_members?(%{ game: game, player_id: player_id, event: event }) do
    members =
      event
      |> Map.fetch!(:members)
      |> case do
           [] -> []
           members -> Enum.filter(members, fn id -> id != player_id end)
         end
    length(members) == 0
  end

  def add_event(%{ game: game, player_id: player_id, event_id: event_id } = args) do
    player = Player.get(game, player_id)
    %Event{} = event = Enum.find(player.events, fn e -> e.event_id == event_id end)
    Map.put(args, :event, event)
  end

  def set_event_type(args) do
    Map.put(args, :type, :auction)
  end

  def can_someone_buy?(%{ game: game, player_id: player_id, amount: amount }) do
    game.players
    |> Enum.filter(fn p -> p.player_id != player_id end)
    |> Enum.any?(fn p -> p.surrender != true and p.balance >= amount end)
  end

  def set_bid_amount(%{ game: game, player_id: player_id } = args) do
    player = Player.get(game, player_id)
    amount = Enum.find(player.events, fn e -> e.type == :auction end)
             |> Map.fetch!(:amount)
    Map.put(args, :amount, amount)
  end

  def set_next_bid_amount(%{ game: game, amount: amount } = args) do
    Map.put(args, :amount, amount + 100)
  end

  def set_members(%{ event: event } = args) do
    Map.put(args, :members, event.members)
  end

  def card_exists?(%{ game: game, position: position }) do
    card = Card.get_by_position(game, position)
    card != nil
  end

  def add_card(%{game: game, player_id: player_id, position: position} = args) do
    %Card{} = card = Card.get_by_position(game, position)
    Map.put(args, :card, card)
  end

  def add_player(%{game: game, player_id: player_id, position: position} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    Map.put(args, :player, player)
  end

  def add_position(%{game: game, player_id: player_id, event_id: event_id} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    event = Enum.find(player.events, fn e -> e.event_id == event_id end)
    Map.put(args, :position, event.position)
  end

  def has_enough_money?(%{ player: player, amount: amount }) do
    player.balance >= amount
  end


end
