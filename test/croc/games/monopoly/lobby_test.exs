defmodule Croc.GamesTest.MonopolyTest.LobbyTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly.Lobby
  }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer

  describe "create lobby" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      %{
        players_ids: players_ids
      }
    end

    test "should create lobby with 1 player in it", context do
      player_id = Enum.at(context.players_ids, 0)
      {:ok, %Lobby{} = lobby} = Lobby.create(player_id, [])

      {:ok, players} =
        Memento.transaction(fn ->
          Memento.Query.select(LobbyPlayer, {:==, :lobby_id, lobby.lobby_id})
        end)

      assert lobby.lobby_id == List.first(players) |> Map.fetch!(:lobby_id)
      assert is_list(players)
      assert length(players) == 1

      result = Lobby.create(player_id, [])
      assert {:error, :already_in_lobby} == result

      join_result = Lobby.join(lobby.lobby_id, player_id)
      assert {:error, :already_in_lobby} == join_result
    end
  end

  describe "join lobby" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      player_id = Enum.at(players_ids, 0)
      {:ok, %Lobby{} = lobby} = Lobby.create(player_id, [])
      %{
        players_ids: players_ids,
        lobby: lobby
      }
    end

    test "should successfully join lobby", %{ lobby: lobby, players_ids: players_ids } do
      player_id = Enum.at(players_ids, 1)
      {:ok, %Lobby{} = updated_lobby} = Lobby.join(lobby.lobby_id, player_id)
      assert length(updated_lobby.players) == 2
      assert Enum.find(updated_lobby.players, fn p -> p.player_id == player_id end) != nil
    end

    test "should throw if already in this lobby", %{ lobby: lobby, players_ids: players_ids } do
      player_id = Enum.at(players_ids, 1)
      {:ok, %Lobby{} = updated_lobby} = Lobby.join(lobby.lobby_id, player_id)
      assert length(updated_lobby.players) == 2
      assert Enum.find(updated_lobby.players, fn p -> p.player_id == player_id end) != nil
      result = Lobby.join(lobby.lobby_id, player_id)
      assert result == {:error, :already_in_lobby}
    end

    test "should throw if this lobby not exists", %{ players_ids: players_ids } do
      player_id = Enum.at(players_ids, 1)
      result = Lobby.join(Ecto.UUID.generate, player_id)
      assert result == {:error, :no_lobby}
    end
  end

  describe "leave lobby" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      player_id = Enum.at(players_ids, 0)
      {:ok, %Lobby{} = lobby} = Lobby.create(player_id, [])
      %{
        players_ids: players_ids,
        lobby: lobby
      }
    end

    test "should successfully leave lobby", %{ lobby: lobby, players_ids: players_ids } do
      player_id = Enum.at(players_ids, 1)
      {:ok, %Lobby{} = joined_lobby} = Lobby.join(lobby.lobby_id, player_id)
      assert length(joined_lobby.players) == 2
      assert Enum.find(joined_lobby.players, fn p -> p.player_id == player_id end) != nil
      {:ok, %Lobby{} = updated_lobby} = Lobby.leave(lobby.lobby_id, player_id)

      assert length(updated_lobby.players) == 1
      assert Enum.find(updated_lobby.players, fn p -> p.player_id == player_id end) == nil
    end

    test "should throw if not in this lobby", %{ lobby: lobby, players_ids: players_ids } do
      player_id = Enum.at(players_ids, 1)
      result = Lobby.leave(lobby.lobby_id, player_id)
      assert result == {:error, :not_in_lobby}
    end

    test "should throw if this lobby not exists", %{ players_ids: players_ids } do
      player_id = Enum.at(players_ids, 1)
      result = Lobby.leave(Ecto.UUID.generate, player_id)
      assert result == {:error, :no_lobby}
    end
  end
end
