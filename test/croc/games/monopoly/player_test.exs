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

    {:ok, %Lobby{} = lobby} = Lobby.create(Enum.at(@players_ids, 0), [])

    Enum.slice(@players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
    end)

    {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
    %{game: game}
  end

  test "Update player", context do
    player_id = Enum.at(@players_ids, 0)
    player = Enum.at(context.game.players, 0)
    player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
    assert player_index != nil

    %Monopoly{} =
      game =
      Player.update(context.game, player_id, %Player{player | balance: player.balance + 500})

    updated_player = Enum.at(game.players, 0)
    expected_player = %Player{player | balance: player.balance + 500}
    assert player.balance + 500 == updated_player.balance
    assert expected_player == updated_player
  end

  describe "Give money" do
    test "should successfully give money", context do
      player_id = Enum.at(@players_ids, 0)
      player = Enum.at(context.game.players, 0)
      player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
      assert player_index != nil
      amount = 500
      %Monopoly{} = game = Player.give_money(context.game, player_id, amount)

      updated_player = Enum.at(game.players, 0)
      expected_player = %Player{player | balance: player.balance + amount}
      assert player.balance + amount == updated_player.balance
      assert expected_player == updated_player
    end
  end

  describe "Take money" do
    test "should throw if not enough money", context do
      player_id = Enum.at(@players_ids, 0)
      player = Enum.at(context.game.players, 0)
      assert player != nil
      amount = 500
      result = Player.take_money(context.game, player_id, amount)
      assert result == {:error, :not_enough_money}
    end

    test "should successfully take money", context do
      player_id = Enum.at(@players_ids, 0)
      amount = 500
      updated_players = context.game.players
                        |> Enum.map(fn p ->
        unless p.player_id != player_id do
          Map.put(p, :balance, amount)
        else
          p
        end
      end)
      updated_game = Map.put(context.game, :players, updated_players)
      player = Enum.at(updated_game.players, 0)
      assert player != nil
      assert player.balance >= amount
      %Monopoly{} = game = Player.take_money(updated_game, player_id, amount)

      updated_player = Enum.at(game.players, 0)
      expected_player = %Player{player | balance: player.balance - amount}
      assert player.balance - amount == updated_player.balance
      assert expected_player == updated_player
    end
  end


  describe "Transfer money" do
    test "should throw if sender has not enough money", context do
      player_id = Enum.at(@players_ids, 0)
      receiver_player_id = Enum.at(@players_ids, 1)
      receiver = Enum.at(context.game.players, 1)
      player = Enum.at(context.game.players, 0)
      assert player != nil
      assert receiver != nil
      amount = 500
      result = Player.transfer(context.game, player_id, receiver_player_id, amount)
      assert result == {:error, :not_enough_money}
    end

    test "should successfully transfer money", context do
      amount = 500
      player_id = Enum.at(@players_ids, 0)
      receiver_player_id = Enum.at(@players_ids, 1)
      receiver = Enum.at(context.game.players, 1)
      updated_players = context.game.players
                        |> Enum.map(fn p ->
        unless p.player_id != player_id do
          Map.put(p, :balance, amount)
        else
          p
        end
      end)
      updated_game = Map.put(context.game, :players, updated_players)
      player = Enum.at(updated_game.players, 0)
      assert player.balance >= amount
      assert player != nil
      assert receiver != nil
      %Monopoly{} = game = Player.transfer(updated_game, player_id, receiver_player_id, amount)

      updated_player = Enum.at(game.players, 0)
      expected_player = %Player{player | balance: player.balance - amount}
      assert player.balance - amount == updated_player.balance
      assert expected_player == updated_player
    end
  end
end
