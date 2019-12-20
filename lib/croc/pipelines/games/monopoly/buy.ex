defmodule Croc.Pipelines.Games.Monopoly.Buy do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
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
  check :has_enough_money?, error_message: :not_enough_money
  step :set_amount
  step :buy, with: &Card.buy/1
  step :take_money, with: &Player.take_money/1
  step :remove_event, with: &Event.remove_player_event/1
  step :process_player_turn, with: &Monopoly.process_player_turn/1
  tee :send_buy_event
  step :set_timeout_callback
  link CreatePlayerTimeout

  def set_timeout_callback(args), do: Map.put(args, :on_timeout, :surrender)

  def send_buy_event(%{ game: game, player_id: player_id, card: card }) do
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{player_id} покупает #{card.name} за #{card.cost}") })
  end

  def set_event_type(args) do
    Map.put(args, :type, :free_card)
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
