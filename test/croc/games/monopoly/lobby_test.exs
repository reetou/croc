defmodule Croc.GamesTest.MonopolyTest.LobbyTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly.Lobby
  }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer

  describe "create lobby" do
    setup do
      %{players_ids: Enum.take_random(1..999_999, 5)}
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

      join_result = Lobby.join(123, player_id)
      assert {:error, :already_in_lobby} == join_result
    end
  end

  describe "join lobby" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      {:ok, %Lobby{} = lobby} = Lobby.create(Enum.at(players_ids, 0), [])
      %{lobby: lobby, players_ids: players_ids}
    end

    test "should join player", context do
      player_id = Enum.at(context.players_ids, 1)
      :ok = Lobby.join(context.lobby.lobby_id, player_id)

      {:ok, players} =
        Memento.transaction(fn ->
          Memento.Query.select(LobbyPlayer, {:==, :lobby_id, context.lobby.lobby_id})
        end)

      player = Enum.at(players, 1)
      assert player != nil
      assert player.lobby_id == context.lobby.lobby_id
      assert player.player_id == player_id

      result = Lobby.create(player_id, [])
      assert {:error, :already_in_lobby} == result

      join_result = Lobby.join(123, player_id)
      assert {:error, :already_in_lobby} == join_result
    end
  end

  describe "leave lobby" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      {:ok, %Lobby{} = lobby} = Lobby.create(Enum.at(players_ids, 0), [])
      %{lobby: lobby, players_ids: players_ids}
    end

    test "should leave lobby for player", context do
      player_id = Enum.at(context.players_ids, 1)
      other_player_id = Enum.at(context.players_ids, 2)
      :ok = Lobby.join(context.lobby.lobby_id, player_id)
      :ok = Lobby.leave(context.lobby.lobby_id, player_id)

      {:ok, players} =
        Memento.transaction(fn ->
          Memento.Query.select(LobbyPlayer, {:==, :lobby_id, context.lobby.lobby_id})
        end)

      player = Enum.at(players, 1)
      assert player == nil

      {:ok, %Lobby{}} = Lobby.create(player_id, [])

      result = Lobby.leave(123, other_player_id)
      assert {:error, :not_in_lobby} == result
    end
  end
end
