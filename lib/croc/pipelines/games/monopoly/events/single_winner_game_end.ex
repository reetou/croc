defmodule Croc.Pipelines.Games.Monopoly.SingleWinnerGameEnd do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.MonopolyChannel
  alias Croc.Games.Monopoly.Supervisor, as: MonopolySupervisor
  use Opus.Pipeline

  check :last_player_left?, error_message: :has_players
  step :set_player
  step :reset_player_turn
  step :set_ended_time
  step :set_winner
  tee :send_win_event
  tee :broadcast_game_end_event
  step :end_game

  def broadcast_game_end_event(args) do
    :ok = MonopolyChannel.send_game_end_event(args)
  end

  def end_game(args) do
    sleep_time = case Mix.env() do
      :test -> 1
      _ -> 20000
    end
    {:ok, pid} = Task.start(fn ->
      Process.sleep(sleep_time)
      :ok = Monopoly.end_game(args)
    end)
    args
  end

  def last_player_left?(%{ game: game }) do
    players =
      game.players
      |> Enum.filter(fn p -> p.surrender != true end)
    length(players) == 1
  end

  def set_player(%{ game: game } = args) do
    %Player{} = player =
      game.players
      |> Enum.filter(fn p -> p.surrender != true end)
      |> List.first()
    Map.put(args, :player_id, player.player_id)
  end

  def send_win_event(%{ game: game, player_id: player_id }) do
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{player_id} побеждает в игре!") })
  end

  def reset_player_turn(%{ game: game } = args) do
    Map.put(args, :game, Map.put(game, :player_turn, nil))
  end

  def set_ended_time(%{ game: game } = args) do
    ended_at = DateTime.utc_now() |> DateTime.truncate(:second)
    Map.put(args, :game, Map.put(game, :ended_at, ended_at))
  end

  def set_winner(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Map.put(game, :winners, [player_id]))
  end
end
