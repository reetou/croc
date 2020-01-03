defmodule Croc.Pipelines.Games.Monopoly.EventCards.ForceTeleportation do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.EventCard
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout,
    AuctionRequest
    }
  use Opus.Pipeline

  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  check :can_use?, with: &EventCard.can_use?/1, error_message: :too_early_to_use
  check :check_type?, error_message: :invalid_event_card_type
  check :has_event_card?, error_message: :no_available_event_card
  check :has_position?, error_message: :invalid_position
  check :has_enough_money?, error_message: :not_enough_money
  step :add_card
  step :mark_used, with: &EventCard.mark_used/1
  step :take_money_from_caller
  step :update_players
  tee :send_event
  # Отправить ивент о том что все игроки были перенесены на позицию
  # И что они не платят за наступление на карточку

  def send_event(%{ game: game, player_id: player_id, card: card }) do
    %Player{name: name} = Player.get(game, player_id)
    message = "#{name} переносит всех на #{card.name}. Телепортированные ничего не платят за попадание"
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored(message) })
  end

  def update_players(%{ game: game, position: position } = args) do
    players =
      game.players
      |> Enum.filter(fn p -> p.surrender != true end)
      |> Enum.map(fn p -> Map.put(p, :position, position) end)
    args
    |> Map.put(:game, Map.put(game, :players, players))
  end

  def add_card(%{game: game, player_id: player_id, position: position} = args) do
    %Card{} = card = Card.get_by_position(game, position)
    Map.put(args, :card, card)
  end

  def has_position?(args) do
    position = Map.get(args, :position)
    position != nil and position >= 0
  end

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :auction_reject)
  end

  def has_cards_on_loan?(%{ game: game, player_id: player_id }) do
    game.cards
    |> Enum.filter(fn c -> c.owner != nil end)
    |> Enum.filter(fn c -> not_in_monopoly?(%{ game: game, card: c }) end)
    |> Enum.any?(fn c -> c.on_loan == true end)
  end

  def update_cards(%{ game: game } = args) do
    cards_ids = game.cards
                |> Enum.filter(fn c -> c.owner != nil end)
                |> Enum.filter(fn c -> not_in_monopoly?(%{ game: game, card: c }) end)
                |> Enum.filter(fn c -> c.on_loan == true end)
                |> Enum.map(fn c -> c.id end)
    cards = Enum.map(game.cards, fn c ->
      unless Enum.member?(cards_ids, c.id) == false do
        Card.reset(c)
      else
        c
      end
    end)
    game =
      game
      |> Map.put(:cards, cards)
    args
    |> Map.put(:game, game)
    |> Map.put(:updated_cards, Enum.filter(cards, fn c -> c.id in cards_ids end))
  end

  def not_in_monopoly?(%{ game: game, card: card }) do
    game.cards
    |> Enum.filter(fn c ->
      c.monopoly_type != nil and c.monopoly_type == card.monopoly_type
    end)
    |> Enum.uniq_by(fn c -> c.owner end)
    |> length()
    |> case do
         1 -> false
         _ -> true
       end
  end

  def take_money_from_caller(%{ game: game, type: type } = args) do
    cost = EventCard.get_cost(game, type)
    args
    |> Map.put(:amount, cost)
    |> Player.take_money()
  end

  def has_event_card?(args) do
    case EventCard.get_by_type(args) do
      %EventCard{} -> true
      _ -> false
    end
  end

  def check_type?(args) do
    type = Map.get(args, :type)
    type == :force_teleportation
  end

  def has_enough_money?(%{ game: game, player_id: player_id, type: type }) do
    cost = EventCard.get_cost(game, type)
    %Player{} = player = Player.get(game, player_id)
    player.balance >= cost
  end

end
