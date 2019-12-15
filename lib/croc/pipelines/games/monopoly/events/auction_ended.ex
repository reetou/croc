defmodule Croc.Pipelines.Games.Monopoly.Events.AuctionEnded do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  require Logger
  use Opus.Pipeline

  step :take_money_from_bidder, with: &Player.take_money/1, if: :has_bidder?
  step :give_card_to_bidder, with: &Card.buy/1, if: :has_bidder?
  tee :send_bidder_bought_event, if: :has_bidder?
  tee :send_nobody_bought_event, unless: :has_bidder?
  step :set_player_id_back_to_auction_starter
  step :process_player_turn, with: &Monopoly.process_player_turn/1

  def has_bidder?(%{ event: event }) do
    event.last_bidder != nil
  end

  def add_roll_event(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Event.add_player_event(game, player_id, Event.roll(player_id)))
  end

  def set_player_id_back_to_auction_starter(%{ game: game, event: event } = args) do
    Map.put(args, :player_id, event.starter)
  end

  def send_bidder_bought_event(%{ game: game, card: card, player_id: player_id, amount: amount }) do
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("Игрок #{player_id} выкупает карточку #{card.name} за #{amount}k") })
  end

  def send_nobody_bought_event(%{card: card, game: game} = args) do
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("Никто не выкупил карточку #{card.name}") })
  end

  def no_members?(%{ members: members }) do
    length(members) == 0
  end

end
