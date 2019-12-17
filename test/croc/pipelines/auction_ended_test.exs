defmodule Croc.PipelinesTest.Games.Monopoly.AuctionEnded do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    Surrender,
    Events.AuctionEnded
  }

  def get_random_cards_with_index(cards, amount, type) do
    new_cards =
      cards
      |> Enum.filter(fn c -> c.type == type end)
      |> Enum.take_random(amount)
      |> Enum.map(
           fn c ->
             index = Enum.find_index(cards, fn zc -> zc.id == c.id end)
             {c, index}
           end
         )
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

  describe "Auction end when event starter surrendered" do

    setup %{ game: game } do
      %Player{} = player = Player.get(game, game.player_turn)
      %Event{event_id: roll_event_id} = Event.get_by_type(game, player.player_id, :roll)
      %Player{} = auction_starter_player = Enum.at(game.players, 3)
      %Event{} = event = Event.auction(1500, "", 8, auction_starter_player.player_id, nil, [])
      game =
        game
        |> Event.remove_player_event(player.player_id, roll_event_id)
        |> Player.put(event.starter, :surrender, true)
      players_ids =
        game.players
        |> Enum.map(fn p -> p.player_id end)
      current_player_index = Enum.find_index(players_ids, fn id -> id == event.starter end)
      next_player_id = Enum.at(players_ids, current_player_index + 1, Enum.at(players_ids, 0))
      %{ game: game, event: event, next_player_id: next_player_id }
    end

    test "should process player turn to next player after auction starter", %{ game: game, event: event, next_player_id: next_player_id } do
      %Player{} = player = Player.get(game, event.starter)
      {:ok, args} = AuctionEnded.call(%{
        game: game,
        player_id: player.player_id,
        event: event
      })
      game = args.game
      assert game.player_turn == next_player_id
      %Player{} = player = Player.get(game, player.player_id)
      %Player{} = next_player = Player.get(game, next_player_id)
      assert length(player.events) == 0
      assert player.surrender == true
      %Event{} = event = Event.get_by_type(game, next_player.player_id, :roll)
    end
  end

end
