defmodule Croc.Pipelines.Games.Monopoly.EventCards.ForceAuction do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.EventCard

  alias Croc.Repo.Games.Monopoly.EventCard, as: RepoEventCard
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
  check :has_position?, error_message: :invalid_auction_position
  step :add_card
  check :has_owner?, error_message: :card_has_no_owner
  check :all_cards_by_monopoly_type_occupied?, error_message: :has_unoccupied_cards
  check :not_in_monopoly?, error_message: :card_in_monopoly
  check :has_enough_money?, error_message: :not_enough_money
  check :can_someone_buy?, error_message: :nobody_can_buy
  step :mark_used, with: &EventCard.mark_used/1
  step :take_money_from_caller
  # Отправить ивент что коллер теряет деньги
  step :give_money_to_card_owner
  tee :send_event
  # Отправить ивент что юзер получает деньги за ивент карточку + за саму карточку
  # И получает меньше денег, если карта была заложена до этого
  step :add_auction_event
  link AuctionRequest

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :auction_reject)
  end

  def send_event(%{ game: game, player_id: player_id, card: card }) do
    %Player{name: name} = Player.get(game, player_id)
    message = "#{name} вытягивает карту и выставляет #{card.name} на аукцион"
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored(message) })
  end

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :auction_reject)
  end

  def add_auction_event(%{ game: game, player_id: player_id, card: card } = args) do
    player = Player.get(game, player_id)
    members = game.players
              |> Enum.filter(fn p -> p.surrender != true and p.balance >= card.cost end)
              |> Enum.map(fn p -> p.player_id end)
    event = Event.auction(card.cost, "Был вынужден задуматься о покупке #{card.name}", card.position, player_id, nil, members)
    args
    |> Map.put(:event, event)
    |> Map.put(:members, event.members)
    |> Map.put(:amount, event.amount)
  end

  def can_someone_buy?(%{ game: game, player_id: player_id, card: card }) do
    game.players
    |> Enum.filter(fn p -> p.player_id != player_id end)
    |> Enum.any?(fn p -> p.surrender != true and p.balance >= card.cost end)
  end

  def take_money_from_caller(%{ game: game, type: type } = args) do
    cost = EventCard.get_cost(game, type)
    args
    |> Map.put(:amount, cost)
    |> Player.take_money()
  end

  def give_money_to_card_owner(%{ game: game, type: type, card: %Card{} = card } = args) do
    cost = EventCard.get_cost(game, type)
    card_cost = cond do
      card.on_loan == true -> card.cost - card.loan_amount
      true -> card.cost
    end
    args
    |> Map.put(:amount, cost + card_cost)
    |> Map.put(:player_id, card.owner)
    |> Player.give_money()
    |> Map.put(:player_id, args.player_id)
  end

  def card_is_on_loan?(%{ card: card }) do
    card.on_loan == true
  end

  def add_card(%{game: game, player_id: player_id, position: position} = args) do
    %Card{} = card = Card.get_by_position(game, position)
    Map.put(args, :card, card)
  end

  def check_type?(args) do
    type = Map.get(args, :type)
    type == :force_auction
  end

  def has_position?(args) do
    position = Map.get(args, :position)
    position != nil and position >= 0
  end

  def has_enough_money?(%{ game: game, player_id: player_id, type: type }) do
    cost = EventCard.get_cost(game, type)
    %Player{} = player = Player.get(game, player_id)
    player.balance >= cost
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

  def has_owner?(%{ card: card }) do
    card.owner != nil
  end

  def all_cards_by_monopoly_type_occupied?(%{ game: game, card: card }) do
    game.cards
    |> Enum.filter(fn c ->
      c.monopoly_type != nil and c.monopoly_type == card.monopoly_type
    end)
    |> Enum.all?(fn c -> c.owner != nil end)
  end

end
