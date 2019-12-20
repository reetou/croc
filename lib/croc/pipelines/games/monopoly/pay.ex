defmodule Croc.Pipelines.Games.Monopoly.Pay do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout
  }
  use Opus.Pipeline

  step :set_event_type
  check :is_playing?,      with: &Player.is_playing?/1, error_message: :no_player
  check :can_send_action?, with: &Monopoly.can_send_action?/1, error_message: :not_your_turn
  check :has_event?,  with: &Event.has_by_type?/1, error_message: :no_roll_event
  step :get_event
  step :get_player
  step :set_event_data
  check :has_enough_money?, error_message: :not_enough_money
  step :remove_event, with: &Event.remove_player_event/1
  step :transfer_money, with: &Player.transfer/1, if: :has_receiver?
  step :take_money, with: &Player.take_money/1, unless: :has_receiver?
  step :process_player_turn, with: &Monopoly.process_player_turn/1
  step :set_timeout_callback
  link CreatePlayerTimeout

  def set_timeout_callback(args), do: Map.put(args, :on_timeout, :surrender)

  def set_event_type(args) do
    Map.put(args, :type, :pay)
  end

  def set_event_data(%{ player_id: sender_id, event: %Event{ receiver: receiver_id, amount: amount } } = args) do
    args
    |> Map.put(:sender_id, sender_id)
    |> Map.put(:receiver_id, receiver_id)
    |> Map.put(:amount, amount)
  end

  def get_event(%{ game: game, player_id: player_id, event_id: event_id } = args) do
    with %Event{} = event <- Event.get_by_id(game, player_id, event_id) do
      Map.put(args, :event, event)
    else
      e -> e
    end
  end

  def get_player(%{ game: game, player_id: player_id } = args) do
    with %Player{} = player <- Player.get(game, player_id) do
      Map.put(args, :player, player)
    else
      _ -> {:error, :no_player}
    end
  end

  def has_enough_money?(%{ player: player, event: event }) do
    player.balance >= event.amount
  end

  def has_receiver?(%{ event: event, player_id: player_id }) do
    event.receiver != nil and event.receiver != player_id
  end

end
