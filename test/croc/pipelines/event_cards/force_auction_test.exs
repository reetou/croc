defmodule Croc.PipelinesTest.Games.Monopoly.ForceAuctionTest do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{
    Event,
    Player,
    Lobby,
    Card,
    EventCard
  }
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    EventCards.ForceAuction
  }

  @event_card_type :force_auction

  def game_with_cards_owned_by_different_players(game, no_money_for_players \\ true) do
    caller = Enum.at(game.players, 0)
    players =
      game.players
      |> Enum.map(fn p ->
        if p.player_id != caller.player_id and no_money_for_players do
          Map.put(p, :balance, 0)
        else
          p
        end
      end)
    monopoly_type =
      game.cards
      |> Enum.filter(fn c -> c.monopoly_type != nil end)
      |> Enum.random()
      |> Map.fetch!(:monopoly_type)
    monopoly_cards_ids =
      game.cards
      |> Enum.filter(fn c -> c.monopoly_type == monopoly_type end)
      |> Enum.map(fn c -> c.id end)
    players_limit = length(monopoly_cards_ids)
    random_owners_ids =
      players
      |> Enum.filter(fn p -> p.player_id != caller.player_id end)
      |> Enum.map(fn p -> p.player_id end)
      |> Enum.take_random(players_limit)
    cards_players =
      Range.new(0, players_limit - 1)
      |> Enum.map(fn ind -> {Enum.at(monopoly_cards_ids, ind), Enum.at(random_owners_ids, ind)} end)
      |> Map.new()
    cards =
      game.cards
      |> Enum.map(fn c ->
        unless Map.has_key?(cards_players, c.id) do
          c
        else
          Map.put(c, :owner, Map.fetch!(cards_players, c.id))
        end
      end)
    game =
      game
      |> Map.put(:players, players)
      |> Map.put(:cards, cards)
      |> Map.put(:round, 10)
      |> Map.put(:event_cards, [EventCard.new(@event_card_type)])

    owner = Player.get(game, List.first(random_owners_ids))
    %{ game: game, owner: owner, caller: caller }
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Croc.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Croc.Repo, {:shared, self()})
    end
    players_ids = Enum.take_random(1..999_999, 5)
    {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

    Enum.slice(players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
    end)

    {:ok, %Monopoly{} = game} = Monopoly.start(lobby)

    %{game: game}
  end

  test "should throw error when round is not 10 yet", %{ game: game } do
    %Player{player_id: player_id} = Enum.at(game.players, 0)
    {:error, pipeline_error} = ForceAuction.call(%{
      game: game,
      type: @event_card_type,
      player_id: player_id,
    })
    assert pipeline_error.error == :too_early_to_use
  end

  describe "cards not in monopoly" do
    setup %{ game: game } do
      game_with_cards_owned_by_different_players(game)
    end

    test "should throw :nobody_can_buy error when nobody can buy", %{ game: game, caller: caller, owner: owner } do
      %Player{player_id: player_id} = caller
      %Card{} = card =
        game.cards
        |> Enum.filter(fn c -> c.type == :brand end)
        |> Enum.filter(fn c -> Card.not_in_monopoly?(%{ game: game, card: c }) end)
        |> Enum.find(fn c -> c.owner == owner.player_id end)
      {:error, pipeline_error} = ForceAuction.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: card.position
      })
      assert pipeline_error.error == :nobody_can_buy
    end

    test "should throw error when card has no owner", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      {:error, pipeline_error} = ForceAuction.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: Enum.find(game.cards, fn c -> c.monopoly_type != nil end) |> Map.fetch!(:position)
      })
      assert pipeline_error.error == :card_has_no_owner
    end
  end

  describe "cards in monopoly" do
    setup %{ game: game } do
      owner = Enum.at(game.players, 1)
      caller = Enum.at(game.players, 0)
      monopoly_type =
        game.cards
        |> Enum.filter(fn c -> c.monopoly_type != nil end)
        |> Enum.random()
        |> Map.fetch!(:monopoly_type)
      cards =
        game.cards
        |> Enum.map(fn c ->
          unless c.monopoly_type == monopoly_type do
            c
          else
            Map.put(c, :owner, owner.player_id)
          end
        end)
      game =
        game
        |> Map.put(:cards, cards)
        |> Map.put(:round, 10)
        |> Map.put(:event_cards, [EventCard.new(@event_card_type)])
      %{ game: game, owner: owner, caller: caller }
    end

    test "should throw error when card is in monopoly", %{ game: game, owner: owner } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      {:error, pipeline_error} = ForceAuction.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: Enum.find(game.cards, fn c -> c.monopoly_type != nil and c.owner == owner.player_id end) |> Map.fetch!(:position)
      })
      assert pipeline_error.error == :card_in_monopoly
    end

    test "should throw error when monopoly type has unoccupied cards", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      card = Enum.find(game.cards, fn c -> c.owner != nil end)
      cards = game.cards
             |> Enum.map(fn c ->
        unless c.id == card.id do
          c
        else
          Map.put(c, :owner, nil)
        end
      end)
      game = Map.put(game, :cards, cards)
      owned_card = Enum.find(game.cards, fn c -> c.owner != nil end)
      {:error, pipeline_error} = ForceAuction.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: owned_card.position
      })
      assert pipeline_error.error == :has_unoccupied_cards
    end
  end

  describe "success" do
    setup %{ game: game } do
      game_with_cards_owned_by_different_players(game, false)
    end

    test "should successfuly force auction", %{ game: game, owner: owner, caller: caller } do
      %Player{player_id: player_id} = caller
      %Card{} = card =
        game.cards
        |> Enum.filter(fn c -> c.type == :brand end)
        |> Enum.filter(fn c -> Card.not_in_monopoly?(%{ game: game, card: c }) end)
        |> Enum.find(fn c -> c.owner == owner.player_id end)
      {:ok, args} = ForceAuction.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: card.position
      })
      cost = EventCard.get_cost(game, @event_card_type)
      game = args.game
      player = Player.get(game, player_id)
      updated_owner = Player.get(game, owner.player_id)
      assert player.balance == caller.balance - cost
      assert updated_owner.balance == owner.balance + cost + card.cost
      %Event{} = auction_event = game.players
      |> Enum.flat_map(fn p -> p.events end)
      |> Enum.filter(fn e -> e.type == :auction end)
      |> List.first()
      assert auction_event.starter == caller.player_id
      assert auction_event.position == card.position
      assert auction_event.amount == card.cost
      assert auction_event.last_bidder == nil
      assert auction_event.members == Enum.map(game.players, fn p -> p.player_id end)
      %Event{} = player_event = Event.get_by_type(game, List.first(auction_event.members), :auction)
      assert player_event == auction_event
    end
  end

end
