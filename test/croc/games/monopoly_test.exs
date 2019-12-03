defmodule Croc.GamesTest.MonopolyTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly,
    Monopoly.Card,
    Monopoly.Player,
    Monopoly.Lobby
  }

  setup do
    players_ids = Enum.take_random(1..999_999, 5)
    {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])
    Enum.slice(players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      :ok = Lobby.join(lobby.lobby_id, player_id)
    end)
    {:ok, lobby_players} = Lobby.get_players(lobby.lobby_id)
    IO.inspect(lobby, label: "Created lobby")
    %{
      lobby: lobby,
      lobby_players: lobby_players,
      players_ids: players_ids
    }
  end

  test "should start game for lobby and write game data to mnesia", context do
    {:ok, %Monopoly{} = started_game} = Monopoly.start(context.lobby)
    {:ok, %Monopoly{} = game} =
      Memento.transaction(fn ->
        Memento.Query.read(Monopoly, context.lobby.lobby_id)
      end)
    assert game == started_game
    assert context.lobby.lobby_id == game.game_id
    assert length(context.players_ids) == length(game.players)
    assert Enum.all?(game.players, fn p ->
      p.game_id == game.game_id
      assert Enum.member?(context.players_ids, p.player_id)
    end)
    {:ok, _result} =
      Memento.transaction(fn ->
        players = Memento.Query.select(Player, {:==, :game_id, game.game_id})

        assert Enum.all?(players, fn p ->
          Enum.member?(context.players_ids, p.player_id)
        end)

        assert length(players) == length(context.players_ids)
      end)
  end
end
