defmodule Croc.PipelinesTest.Games.Monopoly.ForceSellLoanTest do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{
    Event,
    Player,
    Lobby,
    Card,
    EventCard
    }
  require Logger
  alias Croc.Repo.Games.Monopoly.EventCard, as: RepoEventCard
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    EventCards.ForceSellLoan
  }

  @event_card_type :force_sell_loan

  def game_with_cards_on_loan_owned_by_different_players(game, no_money_for_players \\ true) do
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
          c
          |> Map.put(:owner, Map.fetch!(cards_players, c.id))
          |> Map.put(:on_loan, true)
        end
      end)
    game =
      game
      |> Map.put(:players, players)
      |> Map.put(:cards, cards)
      |> Map.put(:round, 10)
      |> Map.put(:event_cards, RepoEventCard.get_all())

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
    {:error, pipeline_error} = ForceSellLoan.call(%{
      game: game,
      type: @event_card_type,
      player_id: player_id,
    })
    assert pipeline_error.error == :too_early_to_use
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
            c
            |> Map.put(:owner, owner.player_id)
            |> Map.put(:on_loan, true)
          end
        end)
      game =
        game
        |> Map.put(:cards, cards)
        |> Map.put(:round, 10)
        |> Map.put(:event_cards, RepoEventCard.get_all())
      %{ game: game, owner: owner, caller: caller }
    end

    test "should throw error when no cards on loan, although there are cards on loan in monopoly", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      assert Enum.empty?(game.event_cards) == false
      {:error, pipeline_error} = ForceSellLoan.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: Enum.find(game.cards, fn c -> c.monopoly_type != nil end) |> Map.fetch!(:position)
      })
      assert pipeline_error.error == :no_cards_on_loan
    end

    test "should throw error when not enough money", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      assert Enum.empty?(game.event_cards) == false
      card = Enum.find(game.cards, fn c -> c.owner != nil end)
      cards = game.cards
              |> Enum.map(fn c ->
        unless c.id == card.id do
          c
        else
          Map.put(c, :owner, nil)
        end
      end)
      game =
        game
        |> Map.put(:cards, cards)
        |> Player.put(player_id, :balance, 0)
      owned_card = Enum.find(game.cards, fn c -> c.owner != nil end)
      {:error, pipeline_error} = ForceSellLoan.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
      })
      assert pipeline_error.error == :not_enough_money
    end
  end

  describe "success" do
    setup %{ game: game } do
      game_with_cards_on_loan_owned_by_different_players(game, false)
    end

    test "should successfuly force sell loan", %{ game: game, owner: owner, caller: caller } do
      %Player{player_id: player_id} = caller
      assert Enum.empty?(game.event_cards) == false
      {:ok, args} = ForceSellLoan.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id
      })
      cards_on_loan = Enum.filter(game.cards, fn c -> c.on_loan == true end)
      assert Enum.map(args.updated_cards, fn c -> c.id end) == Enum.map(cards_on_loan, fn c -> c.id end)
      cost = EventCard.get_cost(game, @event_card_type)
      game = args.game
      player = Player.get(game, player_id)
      updated_owner = Player.get(game, owner.player_id)
      assert cost > 0
      assert player.balance == caller.balance - cost
    end
  end

end
