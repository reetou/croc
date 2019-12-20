defmodule Croc.Pipelines.Games.Monopoly.Events.AuctionRequest do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout
  }
  require Logger
  use Opus.Pipeline

  step :overwrite_player_id
  step :add_player
  step :add_auction_event
  step :change_player_turn
  step :set_timeout_callback
  link CreatePlayerTimeout

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :auction_reject)
  end

  def log(args) do
    IO.inspect(args.player_id, label: "Started auction request to next player")
  end

  def overwrite_player_id(%{ game: game, player_id: player_id, event: event } = args) do
    args
    |> Map.put(:player_id, List.first(event.members))
  end

  def add_player(%{game: game, player_id: player_id, position: position} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    Map.put(args, :player, player)
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

  def change_player_turn(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Map.put(game, :player_turn, player_id))
  end
end
