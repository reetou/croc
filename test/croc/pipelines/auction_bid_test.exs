defmodule Croc.PipelinesTest.Games.Monopoly.AuctionBid do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    AuctionBid,
    RejectBuy
  }

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

    player = Enum.at(game.players, 0)
    card = Enum.find(game.cards, fn c -> c.type == :brand end)
    game = game
           |> Event.add_player_event(player.player_id, Event.free_card("Наступает на карточку", card.position))
           |> Player.put(player.player_id, :position, card.position)
    event_id = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :free_card })
               |> Map.fetch!(:event_id)
    {:ok, args} = RejectBuy.call(%{
      game: game,
      player_id: player.player_id,
      event_id: event_id
    })
    %{game: args.game}
  end

  describe "Bid" do
    test "should put a bid and move turn with auction event to next auction member", %{ game: game } do
      player_index = 1
      next_player_index = 2
      player = Enum.at(game.players, player_index)
      assert game.player_turn == player.player_id
      event = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
      event_id = Map.fetch!(event, :event_id)
      old_balance = player.balance
      assert event.starter != nil
      {:ok, args} = AuctionBid.call(%{
        game: game,
        player_id: player.player_id,
        event_id: event_id
      })
      game = args.game
      %Card{} = card = Card.get_by_position(game, event.position)
      player = Enum.at(game.players, player_index)
      next_player = Enum.at(game.players, next_player_index)
      assert player.balance == old_balance
      assert card.owner == nil
      {:error, :no_event} = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
      event = Event.get_by_type(%{ game: game, player_id: next_player.player_id, type: :auction })
      assert event.starter != nil
      assert game.player_turn == next_player.player_id
      assert %Event{} = event
      assert event.amount == card.cost + 100
      assert event.last_bidder == player.player_id
      assert Enum.member?(event.members, player.player_id)
    end
  end

  describe "Auction end after bid" do
    setup %{ game: game } do
      first_player = Enum.at(game.players, 0)
      player = Enum.at(game.players, 1)
      bidder_player = Enum.at(game.players, 4)
      %Event{} = roll_event = Event.get_by_type(game, first_player.player_id, :roll)
      %Event{} = event = Event.get_by_type(game, player.player_id, :auction)
      |> Map.put(:last_bidder, nil)
      |> Map.put(:members, [bidder_player.player_id])
      game =
        game
        |> Event.remove_player_event(first_player.player_id, roll_event.event_id)
        |> Event.remove_player_event(player.player_id, event.event_id)
        |> Event.add_player_event(bidder_player.player_id, event)
        |> Map.put(:player_turn, bidder_player.player_id)
      %{ game: game, bidder_player: bidder_player }
    end

    test "Should set as bidder and end auction", %{ game: game, bidder_player: bidder_player } do
      %Event{ event_id: event_id } = event = Event.get_by_type(game, bidder_player.player_id, :auction)
      {:ok, args} = AuctionBid.call(%{
        game: game,
        player_id: bidder_player.player_id,
        event_id: event_id
      })
      game = args.game
      first_player = Enum.at(game.players, 0)
      player_ids = Enum.map(game.players, fn p -> p.player_id end)
      index = Enum.find_index(player_ids, fn id -> id == event.starter end)
      %Card{} = card = Card.get_by_position(game, event.position)
      expected_player_turn = Enum.at(game.players, index + 1, first_player)
      assert card.owner == bidder_player.player_id
      assert game.player_turn == expected_player_turn.player_id
    end
  end

end
