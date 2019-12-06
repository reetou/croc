defmodule Croc.GamesTest.MonopolyTest.CardTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly,
    Monopoly.Card,
    Monopoly.Player,
    Monopoly.Lobby
  }

  @players_ids Enum.take_random(1..999_999, 5)

  @lobby_id Enum.random(1..120_000)

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

  describe "Get upgrade level multiplier" do
    test "should return multiplier 1 if card type != :brand", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.map(fn c ->
          expected = 1
          result = Card.get_upgrade_level_multiplier(c)
          assert is_integer(result)
          assert expected == result
        end)
    end

    test "should return multiplier for upgrade_level == 1", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Stream.filter(fn c -> c.max_upgrade_level > 0 end)
        |> Enum.random()
        |> (fn struct -> %Card{struct | upgrade_level: 1} end).()

      expected = Enum.at(card.upgrade_level_multipliers, card.upgrade_level - 1)
      result = Card.get_upgrade_level_multiplier(card)
      assert is_integer(result) or is_float(result)
      assert expected == result
    end

    test "should return multiplier for upgrade_level == 2", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Stream.filter(fn c -> c.max_upgrade_level > 0 end)
        |> Enum.random()
        |> (fn struct -> %Card{struct | upgrade_level: 2} end).()

      expected = Enum.at(card.upgrade_level_multipliers, card.upgrade_level - 1)
      result = Card.get_upgrade_level_multiplier(card)
      assert is_integer(result) or is_float(result)
      assert expected == result
    end

    test "should always round to precision 2  and greater than or equal to 0 and final payment_amount should always be integer",
         context do
      [
        {2.3213123123211, 2.32},
        {1.0000001321321321, 1},
        {2, 2},
        {1, 1},
        {1.2543242343242423423, 1.25},
        {0.81293123123, 1},
        {-15, 1},
        {-0.5, 1}
      ]
      |> Enum.each(fn {actual, expected} ->
        card =
          context.game.cards
          |> Stream.filter(fn c -> c.type == :brand end)
          |> Enum.random()
          |> (fn struct ->
                %Card{struct | upgrade_level: 1, upgrade_level_multipliers: [actual]}
              end).()

        amount = Card.get_payment_amount_for_event(card)
        multiplier = Card.get_upgrade_level_multiplier(card)
        assert multiplier == expected
        assert is_integer(amount)
        assert amount > 0
        assert multiplier >= 1
      end)
    end
  end

  describe "Get payment amount for card including upgrade levels" do
    test "should return raw payment amount if upgrade level == 0 and card type is :brand",
         context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Stream.filter(fn c -> c.upgrade_level == 0 end)
        |> Enum.random()

      amount = Card.get_payment_amount_for_event(card)
      assert is_integer(amount)
      assert card.payment_amount == amount
    end

    test "should return payment amount * multiplier if upgrade level == 1 and card type is :brand",
         context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> (fn struct -> %Card{struct | upgrade_level: 1} end).()

      amount = Card.get_payment_amount_for_event(card)
      multiplier = Card.get_upgrade_level_multiplier(card)
      assert is_integer(amount)
      assert card.payment_amount * multiplier == amount
    end

    test "should return payment amount * multiplier if upgrade level == 2 and card type is :brand",
         context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> (fn struct -> %Card{struct | upgrade_level: 2} end).()

      amount = Card.get_payment_amount_for_event(card)
      multiplier = Card.get_upgrade_level_multiplier(card)
      assert is_integer(amount)
      assert card.payment_amount * multiplier == amount
    end

    test "should return raw payment amount if card type == :payment and upgrade_level == 1",
         context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :payment end)
        |> Stream.filter(fn c -> c.max_upgrade_level > 0 end)
        |> Enum.random()
        |> (fn struct -> %Card{struct | upgrade_level: 1} end).()

      amount = Card.get_payment_amount_for_event(card)
      multiplier = Card.get_upgrade_level_multiplier(card)
      assert is_integer(amount)
      assert card.payment_amount * multiplier == amount
    end

    test "should return raw payment amount if card type == :payment and upgrade_level == 2",
         context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :payment end)
        |> Stream.filter(fn c -> c.max_upgrade_level > 0 end)
        |> Enum.random()
        |> (fn struct -> %Card{struct | upgrade_level: 2} end).()

      amount = Card.get_payment_amount_for_event(card)
      multiplier = Card.get_upgrade_level_multiplier(card)
      assert is_integer(amount)
      assert card.payment_amount * multiplier == amount
    end
  end

  describe "Upgrade card" do
    test "should throw when card not found in game by internal primary id", context do
      card =
        context.game.cards
        |> Enum.random()

      card = %Card{card | id: card.id + 10000}
      player = context.game.players |> Enum.at(0)
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :unknown_game_card}
    end

    test "should throw when player not found in game by player_id", context do
      card =
        context.game.cards
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | player_id: player.player_id + 10000}
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :unknown_game_player}
    end

    test "should throw when card has no owner", context do
      card =
        context.game.cards
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :card_has_no_owner}
    end

    test "should throw when card type != :brand", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      card = %Card{card | owner: player.player_id}
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :card_not_brand}
    end

    test "should throw when player is not an owner for this card", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      another_player = context.game.players |> Enum.at(1)
      card = %Card{card | owner: another_player.player_id}
      player = context.game.players |> Enum.at(0)
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :player_not_owner}
    end

    test "should throw when player does not have enough money", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      card = %Card{card | owner: player.player_id}
      assert player.balance < card.upgrade_cost
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :not_enough_money}
    end

    test "should throw when maximum upgrade level reached", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, upgrade_level: card.max_upgrade_level}
      assert player.balance >= card.upgrade_cost
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :max_upgrade_level_reached}
    end

    test "should throw when card is on loan", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, on_loan: true}
      assert card.on_loan == true
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :card_on_loan}
    end

    test "should return updated game and player on success", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)

      player_index =
        Enum.find_index(context.game.players, fn p -> p.player_id == player.player_id end)

      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, on_loan: false}
      assert card.on_loan == false

      {:ok, %Monopoly{} = game, %Player{} = updated_player} =
        result = Card.upgrade(context.game, player, card)

      updated_card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
      updated_card = Enum.at(game.cards, updated_card_index)

      updated_player_index =
        Enum.find_index(game.players, fn p -> p.player_id == updated_player.player_id end)

      expected_payment_amount =
        Card.get_payment_amount_for_event(%Card{card | upgrade_level: updated_card.upgrade_level})

      assert player_index == updated_player_index
      assert updated_player.player_id == player.player_id
      assert updated_card != nil
      assert updated_card.upgrade_level == card.upgrade_level + 1
      assert updated_player.balance == player.balance - card.upgrade_cost
      assert updated_player.balance == player.balance - updated_card.upgrade_cost
      assert card.payment_amount != updated_card.payment_amount
      assert expected_payment_amount == updated_card.payment_amount
    end
  end
end
