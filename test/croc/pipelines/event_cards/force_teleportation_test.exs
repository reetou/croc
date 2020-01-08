defmodule Croc.PipelinesTest.Games.Monopoly.ForceTeleportationTest do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{
    Event,
    Player,
    Lobby,
    Card,
    EventCard
    }
  alias Croc.Repo.Games.Monopoly.EventCard, as: RepoEventCard
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    EventCards.ForceTeleportation
    }

  @event_card_type :force_teleportation

  def game_with_event_card(game, no_money_for_players \\ true) do
    caller = Enum.at(game.players, 0)
    players =
      game.players
      |> Enum.map(fn p ->
        if no_money_for_players do
          Map.put(p, :balance, 0)
        else
          p
        end
      end)
    game =
      game
      |> Map.put(:players, players)
      |> Map.put(:round, 10)
      |> Map.put(:event_cards, RepoEventCard.get_all())

    %{ game: game, caller: caller }
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
    {:error, pipeline_error} = ForceTeleportation.call(%{
      game: game,
      type: @event_card_type,
      player_id: player_id,
    })
    assert pipeline_error.error == :too_early_to_use
  end

  describe "when no money" do
    setup %{ game: game } do
      game_with_event_card(game)
    end

    test "should throw error not enough money", %{ game: game, caller: caller } do
      %Player{player_id: player_id} = caller
      %Card{} = card =
        game.cards
        |> Enum.random()
      {:error, pipeline_error} = ForceTeleportation.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: card.position
      })
      assert pipeline_error.error == :not_enough_money
    end
  end

  describe "success" do
    setup %{ game: game } do
      game_with_event_card(game, false)
    end

    test "should successfuly force teleportation", %{ game: game, caller: caller } do
      %Player{player_id: player_id} = caller
      %Card{} = card =
        game.cards
        |> Enum.random()
      {:ok, args} = ForceTeleportation.call(%{
        game: game,
        type: @event_card_type,
        player_id: player_id,
        position: card.position
      })
      cost = EventCard.get_cost(game, @event_card_type)
      game = args.game
      player = Player.get(game, player_id)
      assert player.balance == caller.balance - cost
      assert Enum.all?(game.players, fn p -> p.position == card.position end) == true
    end
  end

end
