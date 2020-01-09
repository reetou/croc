defmodule Croc.Pipelines.Games.Monopoly.Events.AuctionBidRequest do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout
  }
  alias CrocWeb.MonopolyChannel
  require Logger
  use Opus.Pipeline

  step :overwrite_player_id_with_next_member
  step :add_player
  step :set_next_bid_amount
  step :add_auction_event
  step :change_player_turn
  step :set_timeout_callback
  link CreatePlayerTimeout
  tee :send_bid_event

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :auction_reject)
  end

  def send_bid_event(%{ game: game, amount: amount, card: card, player: player } = args) do
    %Player{name: name} = Player.get(game, player.player_id)
    event = Event.ignored("#{name} поднимает ставку до #{amount}k за #{card.name}")
    MonopolyChannel.send_event(Map.put(args, :event, event))
  end

  def change_player_turn(%{ player_id: player_id, game: game } = args) do
    Map.put(args, :game, Map.put(game, :player_turn, player_id))
  end

  def overwrite_player_id_with_next_member(%{ event: event, player_id: player_id } = args) do
    current_member_index = Enum.find_index(event.members, fn id -> id == player_id end)
    next_member_id = Enum.at(event.members, current_member_index + 1, Enum.at(event.members, 0))
    Map.put(args, :player_id, next_member_id)
  end

  def set_next_bid_amount(%{ game: game, amount: amount } = args) do
    Map.put(args, :amount, amount + 100)
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

  def add_player(%{game: game, player_id: player_id, position: position} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    Map.put(args, :player, player)
  end

end
