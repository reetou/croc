defmodule Croc.GamesTest.MonopolyTest.LobbyPlayerTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly.Lobby
    }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  
  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Croc.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Croc.Repo, {:shared, self()})
    end
  end

  describe "create lobby" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      player_id = Enum.at(players_ids, 0)
      {:ok, %Lobby{} = lobby} = Lobby.create(player_id, [])

      %{
        players_ids: players_ids,
        lobby: lobby
      }
    end

    test "should successfully create lobbyplayer in mnesia", %{lobby: lobby, players_ids: players_ids} do
      player_id = Enum.at(players_ids, 1)
      {:ok, %LobbyPlayer{} = _player} = LobbyPlayer.create(player_id, lobby.lobby_id)
    end

    test "should successfully delete lobbyplayer from mnesia", %{lobby: lobby, players_ids: players_ids} do
      player_id = Enum.at(players_ids, 1)
      {:ok, %LobbyPlayer{} = player} = LobbyPlayer.create(player_id, lobby.lobby_id)
      :ok = LobbyPlayer.delete(player.player_id, player.lobby_id)
    end

    test "should send :not_found result if lobby player not found", %{lobby: lobby, players_ids: players_ids} do
      player_id = Enum.at(players_ids, 1)
      {:ok, :not_found} = LobbyPlayer.delete(player_id, lobby.lobby_id)
    end
  end
end
