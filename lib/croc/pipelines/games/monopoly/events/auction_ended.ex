defmodule Croc.Pipelines.Games.Monopoly.Events.AuctionEnded do
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

  step :add_player
  step :take_money_from_bidder, with: &Player.take_money/1, if: :has_bidder?
  step :give_card_to_bidder, with: &Card.buy/1, if: :has_bidder?
  tee :send_bidder_bought_event, if: :has_bidder?
  tee :send_nobody_bought_event, unless: :has_bidder?
  step :set_player_id_back_to_auction_starter, unless: :auction_starter_not_playing?
  step :set_player_id_to_player_before_auction_starter, if: :auction_starter_not_playing?
  step :process_player_turn, with: &Monopoly.process_player_turn/1

  step :set_timeout_callback
  link CreatePlayerTimeout

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :surrender)
  end

  def log(args) do
    IO.inspect(args.members, label: "starting auction end, members are")
  end

  def has_bidder?(%{ event: event }) do
    event.last_bidder != nil
  end

  def auction_starter_not_playing?(%{ game: game, event: event }) do
    %Player{} = player = Player.get(game, event.starter)
    player.surrender == true
  end

  def set_player_id_to_player_before_auction_starter(%{ game: game, event: event } = args) do
    players =
      game.players
      |> Enum.filter(fn p -> p.player_id == event.starter or p.surrender != true end)
    starter_index = Enum.find_index(players, fn p -> p.player_id == event.starter end)
    player = Enum.at(players, starter_index - 1, Enum.at(players, 0))
    Map.put(args, :player_id, player.player_id)
  end

  def add_roll_event(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Event.add_player_event(game, player_id, Event.roll(player_id)))
  end

  def set_player_id_back_to_auction_starter(%{ game: game, event: event } = args) do
    Map.put(args, :player_id, event.starter)
  end

  def send_bidder_bought_event(%{ game: game, card: card, player_id: player_id, amount: amount }) do
    %Player{name: name} = Player.get(game, player_id)
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{name} выкупает карточку #{card.name} за #{amount}k") })
  end

  def send_nobody_bought_event(%{card: card, game: game} = args) do
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("Никто не выкупил карточку #{card.name}") })
  end

  def no_members?(%{ members: members }) do
    length(members) == 0
  end

  def add_player(%{game: game, player_id: player_id} = args) do
    player = Player.get(game, player_id)
    Map.put(args, :player, player)
  end
end
