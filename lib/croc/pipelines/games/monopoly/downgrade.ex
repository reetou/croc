defmodule Croc.Pipelines.Games.Monopoly.Downgrade do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  use Opus.Pipeline

  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  check :card_exists?, error_message: :no_card
  step :add_card
  step :add_player
  check :is_owner?, error_message: :player_not_owner
  check :card_type_valid?, error_message: :invalid_card_type
  check :not_on_loan?, error_message: :card_on_loan
  check :upgraded?, error_message: :not_upgraded
  check :in_monopoly?, with: &Card.in_monopoly?/1, error_message: :not_in_monopoly
  check :downgradable?, error_message: :too_large_upgrade_level_difference
  step :set_amount
  step :downgrade, with: &Card.downgrade/1
  step :give_money, with: &Player.give_money/1
  tee :send_downgrade_event

  def send_downgrade_event(%{ game: game, player_id: player_id, card: card }) do
    %Player{name: name} = Player.get(game, player_id)
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{name} продает филиал #{card.name} за #{card.upgrade_cost}") })
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

  def downgradable?(%{ card: card, game: game }) do
    other_cards = Enum.filter(game.cards, fn c -> c.owner == card.owner and c.id != card.id and c.monopoly_type == card.monopoly_type end)
    current_max_card_upgrade_level =
      Enum.max_by(other_cards, fn c -> c.upgrade_level end)
      |> Map.fetch!(:upgrade_level)
    new_upgrade_level = card.upgrade_level - 1
    current_max_card_upgrade_level - new_upgrade_level <= 1
  end

  def upgraded?(%{ card: card }) do
    card.upgrade_level > 0
  end


end
