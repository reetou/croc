defmodule Croc.Pipelines.Games.Monopoly.RejectBuy do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout
  }
  use Opus.Pipeline

  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  step :set_event_type
  check :has_event?,  with: &Event.has_by_type?/1, error_message: :no_free_card_event
  step :add_position
  check :card_exists?, error_message: :no_card
  step :add_card
  step :add_player
  check :no_owner?, error_message: :card_has_owner
  check :card_type_valid?, error_message: :invalid_card_type
  step :set_amount
  step :remove_event, with: &Event.remove_player_event/1
  step :process_buy_turn, with: &Monopoly.process_buy_turn/1, if: :can_someone_buy?
  step :overwrite_player_id, if: :can_someone_buy?
  step :add_player, if: :can_someone_buy?
  step :add_auction_members, if: :can_someone_buy?
  step :add_nobody_bought_event, unless: :can_someone_buy?
  step :process_player_turn, with: &Monopoly.process_player_turn/1, unless: :can_someone_buy?

  step :set_timeout_callback
  link CreatePlayerTimeout

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :auction_reject)
  end

  def overwrite_player_id(%{ game: game, player_id: player_id } = args) do
    args
    |> Map.put(:player_id, game.player_turn)
    |> Map.put(:rejector_id, player_id)
  end

  def add_nobody_bought_event(%{card: card, player: player} = args) do
    Map.put(args, :event, Event.ignored("#{player.player_id} отказывается от покупки. Никто не может выкупить карточку #{card.name}"))
  end

  def set_event_type(args) do
    Map.put(args, :type, :free_card)
  end

  def can_someone_buy?(%{ game: game, player_id: player_id, amount: amount }) do
    game.players
    |> Enum.filter(fn p -> p.player_id != player_id end)
    |> Enum.any?(fn p -> p.surrender != true and p.balance >= amount end)
  end

  def add_auction_members(%{ game: game, player_id: player_id, rejector_id: rejector_id, amount: amount } = args) do
    player = Player.get(game, player_id)
    members = game.players
              |> Enum.filter(fn p -> p.player_id != rejector_id end)
              |> Enum.filter(fn p -> p.surrender != true and p.balance >= amount end)
              |> Enum.map(fn p -> p.player_id end)
    event = Enum.find(player.events, fn e -> e.type == :auction end)
      |> Map.put(:members, members)
    event_index = Enum.find_index(player.events, fn e -> e.event_id == event.event_id end)
    events = List.replace_at(player.events, event_index, event)
    player = Map.put(player, :events, events)
    Map.put(args, :game, Player.replace(game, player_id, player))
  end

  def set_amount(%{ card: card } = args) do
    Map.put(args, :amount, card.cost)
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

  def add_position(%{game: game, player_id: player_id} = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    Map.put(args, :position, player.position)
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

  def has_enough_money?(%{ player: player, card: card }) do
    player.balance >= card.upgrade_cost
  end

  def not_on_loan?(%{ card: card }) do
    card.on_loan != true
  end

  def upgradable?(%{ card: card }) do
    card.upgrade_level < card.max_upgrade_level
  end


end
