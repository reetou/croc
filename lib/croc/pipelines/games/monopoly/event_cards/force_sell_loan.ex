defmodule Croc.Pipelines.Games.Monopoly.EventCards.ForceSellLoan do
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
  check :has_event_card?, with: &EventCard.has_event_card?/1, error_message: :no_available_event_card
  check :has_cards_on_loan?, error_message: :no_cards_on_loan
  check :has_enough_money?, error_message: :not_enough_money
  step :mark_used, with: &EventCard.mark_used/1
  step :take_money_from_caller
  step :update_cards
  tee :send_event
  # Отправить ивент о том что карточки из :updated_cards были сброшены

  def send_event(%{ game: game, player_id: player_id, card: card }) do
    %Player{name: name} = Player.get(game, player_id)
    message = "#{name} вытягивает карту и заставляет всех продать заложенные карты, не состоящие в монополии"
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored(message) })
  end

  def has_cards_on_loan?(%{ game: game }) do
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

  def check_type?(args) do
    type = Map.get(args, :type)
    type == :force_sell_loan
  end

  def has_enough_money?(%{ game: game, player_id: player_id, type: type }) do
    cost = EventCard.get_cost(game, type)
    %Player{} = player = Player.get(game, player_id)
    player.balance >= cost
  end

end
