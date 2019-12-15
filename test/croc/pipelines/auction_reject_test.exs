defmodule Croc.PipelinesTest.Games.Monopoly.AuctionReject do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    AuctionReject,
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
    roll_event = Event.get_by_type(game, player.player_id, :roll)
    game = game
           |> Event.remove_player_event(player.player_id, roll_event.event_id)
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

  describe "Reject" do
    test "should reject auction and move turn with auction event to next auction member", %{ game: game } do
      player_index = 1
      next_player_index = 2
      player = Enum.at(game.players, player_index)
      assert game.player_turn == player.player_id
      event = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
      event_id = Map.fetch!(event, :event_id)
      old_balance = player.balance
      {:ok, args} = AuctionReject.call(%{
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
      assert game.player_turn == next_player.player_id
      expected_members = event.members
                         |> Enum.filter(fn id -> id != player.player_id end)
      assert %Event{} = event
      assert event.starter != nil
      assert event.amount == card.cost
      assert event.members == expected_members
    end
  end

  describe "Auction end after reject" do
    setup %{ game: game } do
      player = Enum.at(game.players, 1)
      assert game.player_turn == player.player_id
      %Event{} = event = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
              |> Map.put(:members, [player.player_id])
      player_index = 2
      auction_player = Enum.at(game.players, player_index)
      game = game
             |> Event.remove_player_event(player.player_id, event.event_id)
             |> Event.add_player_event(auction_player.player_id, event)
             |> Map.put(:player_turn, auction_player.player_id)
      {:error, :no_event} = Event.get_by_type(game, player.player_id, :roll)
      %{ game: game, player_index: player_index }
    end

    test "should reject auction and move turn with auction event to next auction member", %{ game: game, player_index: player_index } do
      player = Enum.at(game.players, player_index)
      next_turn_player = Enum.at(game.players, 1)
      assert game.player_turn == player.player_id
      %Event{} = event = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
      assert event.starter != nil
      event_id = Map.fetch!(event, :event_id)
      old_balance = player.balance
      {:ok, args} = AuctionReject.call(%{
        game: game,
        player_id: player.player_id,
        event_id: event_id
      })
      game = args.game
      next_turn_player = Enum.at(game.players, 1)
      event_starter_player = Enum.at(game.players, 0)
      %Card{} = card = Card.get_by_position(game, event.position)
      player = Enum.at(game.players, player_index)
      assert player.balance == old_balance
      assert card.owner == nil
      {:error, :no_event} = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
      assert game.player_turn == next_turn_player.player_id
      assert %Event{} = Event.get_by_type(%{ game: game, player_id: next_turn_player.player_id, type: :roll })
      assert length(next_turn_player.events) == 1
    end
  end

  describe "Auction end after reject with last bidder" do
    setup %{ game: game } do
      player_index = 1
      bidder_player_index = 4
      player = Enum.at(game.players, player_index)
      bidder_player = Enum.at(game.players, bidder_player_index)
      assert game.player_turn == player.player_id
      %Event{} = event = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
                         |> Map.put(:members, [player.player_id, bidder_player.player_id])
                         |> Map.put(:last_bidder, bidder_player.player_id)
      game = game
             |> Event.remove_player_event(player.player_id, event.event_id)
             |> Event.add_player_event(player.player_id, event)
             |> Map.put(:player_turn, player.player_id)
      %{ game: game, player_index: player_index, bidder_player_index: bidder_player_index }
    end

    test "should reject auction and card should be owned by last bidder", %{ game: game, player_index: player_index, bidder_player_index: bidder_player_index } do
      player = Enum.at(game.players, player_index)
      bidder_player = Enum.at(game.players, bidder_player_index)
      %Event{} = event = Event.get_by_type(game, player.player_id, :auction)
      %Card{} = card = Card.get_by_position(game, event.position)
      assert card.owner == nil
      {:ok, args} = AuctionReject.call(%{
        game: game,
        player_id: player.player_id,
        event_id: event.event_id
      })
      game = args.game
      player = Enum.at(game.players, player_index)
      bidder_player = Enum.at(game.players, bidder_player_index)
      %Card{} = card = Card.get_by_position(game, event.position)
      event_starter_index = Enum.find_index(game.players, fn p -> p.player_id == event.starter end)
      next_turn_player = Enum.at(game.players, event_starter_index + 1)
      assert card.owner == bidder_player.player_id
      assert game.player_turn == next_turn_player.player_id
    end
  end

end
