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
  step :reset_timeout_data


  def has_player_turn?(%{ game: game }) do
    game.player_turn != nil
  end

  def reset_timeout_data(%{ game: game } = args) do
    game =
      game
      |> Map.put(:on_timeout, nil)
    args
    |> Map.put(:game, game)
  end

end
