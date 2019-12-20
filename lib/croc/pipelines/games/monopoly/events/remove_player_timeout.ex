defmodule Croc.Pipelines.Games.Monopoly.Events.RemovePlayerTimeout do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    AuctionReject,
    RejectBuy,
    Surrender
    }
  alias CrocWeb.MonopolyChannel
  require Logger
  use Opus.Pipeline

  check :has_player_turn?, error_message: :no_player_turn
  check :has_timeout_pid?, error_message: :no_timeout_pid
  step :kill_timeout_process, if: :process_alive?
  step :reset_timeout_data


  def has_player_turn?(%{ game: game }) do
    game.player_turn != nil
  end

  def has_timeout_pid?(%{ game: game }) do
    game.timeout_pid != nil
  end

  def process_alive?(%{ game: game }) do
    Process.alive?(game.timeout_pid)
  end

  def kill_timeout_process(%{ game: game } = args) do
    Process.exit(game.timeout_pid, :kill)
    args
  end

  def reset_timeout_data(%{ game: game } = args) do
    game =
      game
      |> Map.put(:timeout_pid, nil)
      |> Map.put(:on_timeout, nil)
    args
    |> Map.put(:game, game)
  end

end
