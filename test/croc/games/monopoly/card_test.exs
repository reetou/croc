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
      {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
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

end
