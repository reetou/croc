defmodule Croc.Pipelines.Games.Monopoly.Roll do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly
  use Opus.Pipeline

  step :set_event_type
  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :has_event?,  with: &Event.has_by_type?/1, error_message: :no_roll_event
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  check :can_roll?,        with: &Player.can_roll?/1, error_message: :cannot_roll
  step  :remove_event, with: &Event.remove_player_event/1
  step  :change_position, with: &Player.change_position/1
  step  :process_position_change, with: &Monopoly.process_position_change/1
  step :process_player_turn, with: &Monopoly.process_player_turn/1

  def set_event_type(args) do
    Map.put(args, :type, :roll)
  end

end
