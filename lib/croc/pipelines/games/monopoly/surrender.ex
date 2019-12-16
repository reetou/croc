defmodule Croc.Pipelines.Games.Monopoly.Surrender do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Pipelines.Games.Monopoly.{
    SingleWinnerGameEnd
  }
  use Opus.Pipeline

  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :not_in_offer?, error_message: :finish_offer_first
  check :not_in_auction?, error_message: :finish_auction_first
  step :set_owned_cards
  tee :send_reset_owned_cards_event, if: :has_cards?
  step :reset_owned_cards
  step :clear_player_events
  step :update_player
  link SingleWinnerGameEnd, if: :last_player_left?
  step :process_player_turn_from_previous_actual_player, if: :is_player_turn?

  def last_player_left?(%{ game: game, player_id: player_id }) do
    players =
      game.players
      |> Enum.filter(fn p -> p.player_id != player_id end)
      |> Enum.filter(fn p -> p.surrender != true end)
    length(players) == 1
  end

  def is_player_turn?(%{ game: game, player_id: player_id } = args) do
    game.player_turn == player_id and last_player_left?(args) == false
  end

  def process_player_turn_from_previous_actual_player(%{ game: game, player_id: player_id } = args) do
    players_ids =
      game.players
      |> Enum.filter(fn p -> p.surrender != true or p.player_id == player_id end)
      |> Enum.map(fn p -> p.player_id end)
    current_player_index = Enum.find_index(players_ids, fn id -> id == player_id end)
    previous_player_id = Enum.at(players_ids, current_player_index - 1, Enum.at(players_ids, 0))
    Monopoly.process_player_turn(%{ game: game, player_id: previous_player_id })
  end

  def update_player(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Player.put(game, player_id, :surrender, true))
  end

  def clear_player_events(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Player.put(game, player_id, :events, []))
  end

  def not_in_offer?(%{ game: game, player_id: player_id } = args) do
    Event.has_by_type?(Map.put(args, :type, :offer)) != true
  end

  def not_in_auction?(%{ game: game, player_id: player_id } = args) do
    is_auction_member = game.players
    |> Enum.flat_map(fn p -> p.events end)
    |> Enum.filter(fn e -> e.type == :auction end)
    |> Enum.any?(fn e -> player_id in e.members end)
    is_auction_member == false
  end

  def has_cards?(%{ owned_cards: owned_cards }) do
    length(owned_cards) > 0
  end

  def send_reset_owned_cards_event(%{ game: game, player_id: player_id, owned_cards: owned_cards }) do
    owned_cards_string =
      owned_cards
      |> Enum.map(fn c -> c.name end)
      |> Enum.join(", ")
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{player_id} сдается и лишается карт #{owned_cards_string}") })
  end

  def set_owned_cards(%{ game: game, player_id: player_id } = args) do
    owned_cards = Enum.filter(game.cards, fn c -> c.owner == player_id end)
    Map.put(args, :owned_cards, owned_cards)
  end

  def reset_owned_cards(%{ game: game, player_id: player_id } = args) do
    cards = game.cards
      |> Enum.map(fn c ->
        unless c.owner != player_id do
          Card.reset(c)
        else
          c
        end
      end)
    game = Map.put(game, :cards, cards)
    Map.put(args, :game, game)
  end
end
