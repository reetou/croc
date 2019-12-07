defmodule Croc.GamesTest.MonopolyTest.PlayerTest do
  use ExUnit.Case
  alias Croc.Games.{
    Monopoly,
    Monopoly.Card,
    Monopoly.Player,
    Monopoly.Lobby
  }


  @players_ids Enum.take_random(1..999_999, 5)

  setup_all tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Croc.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Croc.Repo, {:shared, self()})
    end

    {:ok, lobby} = Lobby.create(Enum.at(@players_ids, 0), [])

    Enum.slice(@players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      :ok = Lobby.join(lobby.lobby_id, player_id)
    end)

    {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
    %{game: game}
  end

  test "Update player", context do
    player_id = Enum.at(@players_ids, 0)
    player = Enum.at(context.game.players, 0)
    player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
    assert player_index != nil
    %Monopoly{} = game = Player.update(context.game, player_id, %Player{player | balance: player.balance + 500})
    updated_player = Enum.at(game.players, 0)
    expected_player = %Player{ player | balance: player.balance + 500 }
    assert player.balance + 500 == updated_player.balance
    assert expected_player == updated_player
  end
end
