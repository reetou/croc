defmodule Croc.Pipelines.Games.Monopoly.Roll do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout
  }
  use Opus.Pipeline

  step :set_event_type
  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :has_event?,  with: &Event.has_by_type?/1, error_message: :no_roll_event
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  check :can_roll?,        with: &Player.can_roll?/1, error_message: :cannot_roll
  step  :remove_event, with: &Event.remove_player_event/1
  step  :change_position, with: &Player.change_position/1
  step  :process_position_change, with: &Monopoly.process_position_change/1
  tee :send_roll_event
  step :process_player_turn, with: &Monopoly.process_player_turn/1

  step :set_timeout_callback
  link CreatePlayerTimeout

  def set_timeout_callback(args) do
    Map.put(args, :on_timeout, :surrender)
  end

  def send_roll_event(%{ dice: dice, game: game, player_id: player_id }) do
    {x, y} = dice
    %Player{} = player = Player.get(game, player_id)
    %Card{} = card = Card.get_by_position(game, player.position)
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{player.name} выбрасывает #{x}:#{y} и попадает на #{card.name}") })
  end

  def set_event_type(args) do
    Map.put(args, :type, :roll)
  end

end
