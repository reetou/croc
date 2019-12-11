defmodule Croc.GamesTest.MonopolyTest.CardTest do
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
      {:ok, lobby} = Lobby.join(lobby.lobby_id, player_id)
    end)

    {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
    %{game: game}
  end

  describe "Get upgrade level multiplier" do
    test "should return multiplier 1 if card type is invalid", context do
      assert length(context.game.cards) > 0

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

        amount = Card.get_payment_amount(card)
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

      amount = Card.get_payment_amount(card)
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

      amount = Card.get_payment_amount(card)
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

      amount = Card.get_payment_amount(card)
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

      amount = Card.get_payment_amount(card)
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

      amount = Card.get_payment_amount(card)
      multiplier = Card.get_upgrade_level_multiplier(card)
      assert is_integer(amount)
      assert card.payment_amount * multiplier == amount
    end
  end

  describe "Downgrade card" do
    test "should throw when card not found in game by internal primary id", context do
      card =
        context.game.cards
        |> Enum.random()

      card = %Card{card | id: card.id + 10000}
      player = context.game.players |> Enum.at(0)
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :unknown_game_card}
    end

    test "should throw when player not found in game by player_id", context do
      card =
        context.game.cards
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | player_id: player.player_id + 10000}
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :unknown_game_player}
    end

    test "should throw when card has no owner", context do
      card =
        context.game.cards
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :card_has_no_owner}
    end

    test "should throw when card type is invalid", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      card = %Card{card | owner: player.player_id}
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :invalid_card_type}
    end

    test "should throw when player is not an owner for this card", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      another_player = context.game.players |> Enum.at(1)
      card = %Card{card | owner: another_player.player_id}
      player = context.game.players |> Enum.at(0)
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :player_not_owner}
    end

    test "should throw when maximum upgrade level reached", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, upgrade_level: 0}
      assert player.balance >= card.upgrade_cost
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :upgrade_level_already_at_minimum}
    end

    test "should throw when card is on loan", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, on_loan: true, upgrade_level: 1}
      assert card.on_loan == true
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :card_on_loan}
    end

    test "should throw when user has no monopoly for this monopoly type", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, upgrade_level: 2}
      result = Card.downgrade(context.game, player, card)
      assert result == {:error, :no_such_monopoly}
    end

    test "should return updated game and player on success with upgrade level 2", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)

      cards =
        context.game.cards
        |> Enum.split_with(fn c -> c.type == :brand and c.monopoly_type == card.monopoly_type end)
        |> case do
          {same_monopoly_cards, other_cards} ->
            Enum.map(same_monopoly_cards, fn smc -> Map.put(smc, :owner, player.player_id) end) ++
              other_cards

          _ ->
            :error
        end

      assert length(context.game.cards) == length(cards)
      assert Enum.all?(cards, fn c -> c.owner == player.player_id end) == false

      player_index =
        Enum.find_index(context.game.players, fn p -> p.player_id == player.player_id end)

      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, on_loan: false, upgrade_level: 2}
      game = Map.put(context.game, :cards, cards)
      assert card.on_loan == false

      {:ok, %Monopoly{} = updated_game, %Player{} = updated_player} =
        Card.downgrade(game, player, card)

      updated_card = Enum.find(updated_game.cards, fn c -> c.id == card.id end)

      updated_player_index =
        Enum.find_index(updated_game.players, fn p -> p.player_id == updated_player.player_id end)

      expected_payment_amount =
        Card.get_payment_amount(%Card{card | upgrade_level: updated_card.upgrade_level})

      assert player_index == updated_player_index
      assert updated_player.player_id == player.player_id
      assert updated_card != nil
      assert updated_card.upgrade_level == card.upgrade_level - 1
      assert updated_player.balance == player.balance + card.upgrade_cost
      assert updated_player.balance == player.balance + updated_card.upgrade_cost
      assert card.payment_amount != updated_card.payment_amount
      assert expected_payment_amount == updated_card.payment_amount
    end

    test "should return updated game and player on success with upgrade level 1", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)

      cards =
        context.game.cards
        |> Enum.split_with(fn c -> c.type == :brand and c.monopoly_type == card.monopoly_type end)
        |> case do
          {same_monopoly_cards, other_cards} ->
            Enum.map(same_monopoly_cards, fn smc -> Map.put(smc, :owner, player.player_id) end) ++
              other_cards

          _ ->
            :error
        end

      assert length(context.game.cards) == length(cards)
      assert Enum.all?(cards, fn c -> c.owner == player.player_id end) == false

      player_index =
        Enum.find_index(context.game.players, fn p -> p.player_id == player.player_id end)

      player = %Player{player | balance: card.cost}

      card =
        card
        |> Map.put(:owner, player.player_id)
        |> Map.put(:on_loan, false)
        |> Map.put(:upgrade_level, 1)
        |> Map.put(
          :payment_amount,
          Card.get_payment_amount(%Card{card | upgrade_level: 1})
        )

      game = Map.put(context.game, :cards, cards)
      assert card.on_loan == false

      {:ok, %Monopoly{} = updated_game, %Player{} = updated_player} =
        Card.downgrade(game, player, card)

      updated_card = Enum.find(updated_game.cards, fn c -> c.id == card.id end)

      updated_player_index =
        Enum.find_index(updated_game.players, fn p -> p.player_id == updated_player.player_id end)

      expected_payment_amount =
        Card.get_payment_amount(%Card{card | upgrade_level: updated_card.upgrade_level})

      assert player_index == updated_player_index
      assert updated_player.player_id == player.player_id
      assert updated_card != nil
      assert updated_card.upgrade_level == card.upgrade_level - 1
      assert updated_player.balance == player.balance + card.upgrade_cost
      assert updated_player.balance == player.balance + updated_card.upgrade_cost
      assert card.payment_amount != updated_card.payment_amount
      assert expected_payment_amount == updated_card.payment_amount
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

    test "should throw when card type is invalid", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      card = %Card{card | owner: player.player_id}
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :invalid_card_type}
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

    test "should throw when user has no monopoly for this monopoly type", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)
      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id}
      result = Card.upgrade(context.game, player, card)
      assert result == {:error, :no_such_monopoly}
    end

    test "should return updated game and player on success", context do
      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = context.game.players |> Enum.at(0)

      cards =
        context.game.cards
        |> Enum.split_with(fn c -> c.type == :brand and c.monopoly_type == card.monopoly_type end)
        |> case do
          {same_monopoly_cards, other_cards} ->
            Enum.map(same_monopoly_cards, fn smc -> Map.put(smc, :owner, player.player_id) end) ++
              other_cards

          _ ->
            :error
        end

      assert length(context.game.cards) == length(cards)
      assert Enum.all?(cards, fn c -> c.owner == player.player_id end) == false

      player_index =
        Enum.find_index(context.game.players, fn p -> p.player_id == player.player_id end)

      player = %Player{player | balance: card.cost}
      card = %Card{card | owner: player.player_id, on_loan: false}
      game = Map.put(context.game, :cards, cards)
      assert card.on_loan == false

      {:ok, %Monopoly{} = updated_game, %Player{} = updated_player} =
        Card.upgrade(game, player, card)

      updated_card = Enum.find(updated_game.cards, fn c -> c.id == card.id end)

      updated_player_index =
        Enum.find_index(updated_game.players, fn p -> p.player_id == updated_player.player_id end)

      expected_payment_amount =
        Card.get_payment_amount(%Card{card | upgrade_level: updated_card.upgrade_level})

      assert player_index == updated_player_index
      assert updated_player.player_id == player.player_id
      assert updated_card != nil
      assert updated_card.upgrade_level == card.upgrade_level + 1
      assert updated_player.balance == player.balance - card.upgrade_cost
      assert updated_player.balance == player.balance - updated_card.upgrade_cost
      assert updated_card.payment_amount > card.raw_payment_amount
      assert updated_card.payment_amount > updated_card.raw_payment_amount
      assert card.payment_amount != updated_card.payment_amount
      assert expected_payment_amount == updated_card.payment_amount
    end
  end

  describe "Buy card" do
    test "should throw if card type is invalid", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.random()

      player = %Player{player | position: card.position}

      result = Card.buy(context.game, player, card)
      assert result == {:error, :invalid_card_type}
    end

    test "should throw if card has no owner", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = %Player{player | position: card.position}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)
      assert length(game.cards) == length(context.game.cards)

      result = Card.buy(game, player, card)
      assert result == {:error, :card_has_no_owner}
    end

    test "should throw if player is not an owner", context do
      player = context.game.players |> Enum.at(0)

      another_player = context.game.players |> Enum.at(1)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      card = %Card{card | owner: another_player.player_id}
      player = %Player{player | position: card.position}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buy(game, player, card)
      assert result == {:error, :player_not_owner}
    end

    test "should throw if player does not have enough money", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      card = %Card{card | owner: player.player_id}
      player = %Player{player | position: card.position}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buy(game, player, card)
      assert result == {:error, :not_enough_money}
    end

    test "should throw if card is already on loan", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, player.player_id)
        |> Map.put(:on_loan, true)

      player = %Player{player | position: card.position, balance: card.cost}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buy(game, player, card)
      assert result == {:error, :on_loan}
    end

    test "should return updated game and player on success", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      card = %Card{card | owner: player.player_id}
      player = %Player{player | position: card.position, balance: card.cost}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      {:ok, %Monopoly{} = game, %Player{} = updated_player} = Card.buy(game, player, card)
      updated_card = Enum.find(game.cards, fn c -> c.id == card.id end)
      assert Enum.all?(game.cards, fn %Card{} = c -> c end)
      assert updated_player.balance + updated_card.cost == player.balance
      assert updated_card.owner == player.player_id
      assert updated_card != nil
    end
  end

  describe "Put on loan" do
    test "should throw if card has invalid card type", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.random()

      result = Card.put_on_loan(context.game, player, card)
      assert result == {:error, :invalid_card_type}
    end

    test "should throw if card has no owner", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      result = Card.put_on_loan(context.game, player, card)
      assert result == {:error, :card_has_no_owner}
    end

    test "should throw if player is not an owner", context do
      player = context.game.players |> Enum.at(0)
      another_player = context.game.players |> Enum.at(1)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, another_player.player_id)

      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)

      game =
        Map.put(
          context.game,
          :cards,
          List.replace_at(context.game.cards, card_index, card)
        )

      result = Card.put_on_loan(game, player, card)
      assert result == {:error, :player_not_owner}
    end

    test "should throw if card is already on loan", context do
      player =
        context.game.players
        |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, player.player_id)
        |> Map.put(:on_loan, true)

      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)

      game =
        Map.put(
          context.game,
          :cards,
          List.replace_at(context.game.cards, card_index, card)
        )

      result = Card.put_on_loan(game, player, card)
      assert result == {:error, :already_on_loan}
    end

    test "should return updated game and player on success", context do
      player =
        context.game.players
        |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, player.player_id)

      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)

      game =
        Map.put(
          context.game,
          :cards,
          List.replace_at(context.game.cards, card_index, %Card{
            card
            | owner: player.player_id,
              on_loan: true
          })
        )

      {:ok, %Monopoly{} = updated_game, %Player{} = updated_player} =
        Card.put_on_loan(game, player, card)

      updated_card = Enum.find(updated_game.cards, fn c -> c.id == card.id end)

      player_in_game =
        Enum.find(updated_game.players, fn p -> p.player_id == updated_player.player_id end)

      assert player_in_game == updated_player
      assert Enum.all?(updated_game.cards, fn %Card{} = c -> c end)
      assert updated_card != nil
      assert updated_card.on_loan == true
      assert updated_card.owner == player.player_id
      assert updated_player.balance - updated_card.loan_amount == player.balance
    end
  end

  describe "Buyout" do
    test "should throw if card type is invalid", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type != :brand end)
        |> Enum.random()

      player = %Player{player | position: card.position}

      result = Card.buyout(context.game, player, card)
      assert result == {:error, :invalid_card_type}
    end

    test "should throw if card has no owner", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      player = %Player{player | position: card.position}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buyout(game, player, card)
      assert result == {:error, :card_has_no_owner}
    end

    test "should throw if player is not an owner", context do
      player = context.game.players |> Enum.at(0)

      another_player = context.game.players |> Enum.at(1)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()

      card = %Card{card | owner: another_player.player_id}
      player = %Player{player | position: card.position}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buyout(game, player, card)
      assert result == {:error, :player_not_owner}
    end

    test "should throw if player does not have enough money", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, player.player_id)

      card = %Card{card | owner: player.player_id}
      player = %Player{player | position: card.position}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buyout(game, player, card)
      assert result == {:error, :not_enough_money}
    end

    test "should throw if card is not on loan", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, player.player_id)
        |> Map.put(:on_loan, false)

      player = %Player{player | position: card.position, balance: card.buyout_cost}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      result = Card.buyout(game, player, card)
      assert result == {:error, :not_on_loan}
    end

    test "should return updated game and player on success", context do
      player = context.game.players |> Enum.at(0)

      card =
        context.game.cards
        |> Stream.filter(fn c -> c.type == :brand end)
        |> Enum.random()
        |> Map.put(:owner, player.player_id)
        |> Map.put(:on_loan, true)

      card = %Card{card | owner: player.player_id}
      player = %Player{player | position: card.position, balance: card.cost}
      card_index = Enum.find_index(context.game.cards, fn c -> c.id == card.id end)
      cards = List.replace_at(context.game.cards, card_index, card)
      game = Map.put(context.game, :cards, cards)

      {:ok, %Monopoly{} = game, %Player{} = updated_player} = Card.buyout(game, player, card)
      updated_card = Enum.find(game.cards, fn c -> c.id == card.id end)
      assert Enum.all?(game.cards, fn %Card{} = c -> c end)
      assert updated_player.balance + updated_card.buyout_cost == player.balance
      assert updated_card.owner == player.player_id
      assert updated_card != nil
    end
  end
end
