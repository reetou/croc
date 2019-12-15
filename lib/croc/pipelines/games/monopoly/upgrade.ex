defmodule Croc.Pipelines.Games.Monopoly.Upgrade do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  use Opus.Pipeline

  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  check :card_exists?, error_message: :no_card
  step :add_card
  step :add_player
  check :is_owner?, error_message: :player_not_owner
  check :card_type_valid?, error_message: :invalid_card_type
  check :not_on_loan?, error_message: :card_on_loan
  check :upgradable?, error_message: :max_upgrade_level_reached
  check :in_monopoly?, with: &Card.in_monopoly?/1, error_message: :not_in_monopoly
  check :has_enough_money?, error_message: :not_enough_money
  step :set_amount
  step :upgrade, with: &Card.upgrade/1
  step :take_money, with: &Player.take_money/1
  tee :send_upgrade_event

  def send_upgrade_event(%{ game: game, player_id: player_id, card: card }) do
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{player_id} покупает филиал #{card.name} за #{card.upgrade_cost}") })
  end

  def set_amount(%{ card: card } = args) do
    Map.put(args, :amount, card.upgrade_cost)
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

  def is_owner?(%{ card: card, player_id: player_id } = args) do
    card.owner == player_id
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
