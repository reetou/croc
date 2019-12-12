defmodule Croc.GamesTest.MonopolyTest.PlayerTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly,
    Monopoly.Player,
    Monopoly.Lobby,
    Monopoly.Event
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

  describe "Can roll" do
    test "should return true if no other events except :roll present", context do
      player_id = Enum.at(@players_ids, 0)
      player = Enum.at(context.game.players, 0)
      player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
      assert player_index != nil
      assert player_id == player.player_id
      %Monopoly{} = game = context.game
      updated_player = Enum.at(game.players, 0)
      assert length(updated_player.events) == 1
      assert Player.can_roll?(game, updated_player.player_id) == true
    end

    test "should return false if no :roll event present", context do
      player_id = Enum.at(@players_ids, 2)
      player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
      player = Enum.at(context.game.players, player_index)
      assert player_index != nil
      assert player_id == player.player_id
      %Monopoly{} = game = context.game
      updated_player = Enum.at(game.players, player_index)
      assert length(updated_player.events) == 0
      result = Player.can_roll?(game, updated_player.player_id)
      assert result == false
    end

    test "should return false if events other than :roll present", context do
      player_id = Enum.at(@players_ids, 0)
      player = Enum.at(context.game.players, 0)
      player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
      assert player_index != nil
      assert player_id == player.player_id
      %Monopoly{} = game = context.game
                           |> Event.add_player_event(player_id, Event.pay(500, "Должен заплатить"))
      updated_player = Enum.at(game.players, 0)
      assert length(updated_player.events) == 2
      result = Player.can_roll?(game, updated_player.player_id)
      |> IO.inspect(label: "At other than result")
      assert result == false
    end

    test "should return error if player_id not exists in game", context do
      player_id = Enum.random(999999..12999999)
      result = Player.can_roll?(context.game, player_id)
      |> IO.inspect(label: "At other than result")
      assert result == {:error, :no_player}
    end
  end

  describe "Give money" do
    test "should successfully give money", context do
      player_id = Enum.at(@players_ids, 0)
      player = Enum.at(context.game.players, 0)
      player_index = Enum.find_index(context.game.players, fn p -> p.player_id == player_id end)
      assert player_index != nil
      amount = 500
      %{ game: %Monopoly{} = game } = Player.give_money(%{ game: context.game, player_id: player_id, amount: amount })

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
      game = Player.update(context.game, player_id, Map.put(player, :balance, 0))
      amount = 500
      result = Player.take_money(%{ game: game, player_id: player_id, amount: amount })
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
      %{ game: %Monopoly{} = game } = Player.take_money(%{ game: updated_game, player_id: player_id, amount: amount })

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
      game = Player.update(context.game, player_id, Map.put(player, :balance, 0))
      assert player != nil
      assert receiver != nil
      amount = 500
      result = Player.transfer(%{ game: game, sender_id: player_id, receiver_id: receiver_player_id, amount: amount })
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
      %{ game: %Monopoly{} = game } = Player.transfer(%{ game: updated_game, sender_id: player_id, receiver_id: receiver_player_id, amount: amount })

      updated_player = Enum.at(game.players, 0)
      expected_player = %Player{player | balance: player.balance - amount}
      assert player.balance - amount == updated_player.balance
      assert expected_player == updated_player
    end
  end
end
