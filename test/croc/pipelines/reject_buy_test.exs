defmodule Croc.PipelinesTest.Games.Monopoly.RejectBuy do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{RejectBuy}

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

  test "should put on auction with all playing members excluding current player", %{ game: game } do
    player = Enum.at(game.players, 0)
    assert game.player_turn == player.player_id
    card = Enum.find(game.cards, fn c -> c.type == :brand end)
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    game = game
           |> Event.add_player_event(player.player_id, Event.free_card("Наступает на карточку", card.position))
           |> Player.put(player.player_id, :position, card.position)
    event_id = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :free_card })
    |> Map.fetch!(:event_id)
    old_balance = player.balance
    {:ok, args} = RejectBuy.call(%{
      game: game,
      player_id: player.player_id,
      event_id: event_id
    })
    game = args.game
    player = Enum.at(game.players, 0)
    next_player = Enum.at(game.players, 1)
    assert player.balance == old_balance
    card = Enum.at(game.cards, card_index)
    assert card.owner == nil
    assert game.player_turn == next_player.player_id
    {:error, :no_event} = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :free_card })
    {:error, :no_event} = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
    event = Event.get_by_type(%{ game: game, player_id: next_player.player_id, type: :auction })
    expected_members = game.players
      |> Enum.filter(fn p -> p.player_id != player.player_id end)
      |> Enum.map(fn p -> p.player_id end)
    assert %Event{} = event
    assert event.amount == card.cost
    assert event.members == expected_members
  end

  test "should put on auction with all playing members excluding current player if player has no money to buy", %{ game: game } do
    player = Enum.at(game.players, 0)
    assert game.player_turn == player.player_id
    card = Enum.find(game.cards, fn c -> c.type == :brand end)
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    game = game
           |> Event.add_player_event(player.player_id, Event.free_card("Наступает на карточку", card.position))
           |> Player.put(player.player_id, :position, card.position)
           |> Player.put(player.player_id, :balance, 1)
    player = Enum.at(game.players, 0)
    event_id = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :free_card })
    |> Map.fetch!(:event_id)
    old_balance = player.balance
    {:ok, args} = RejectBuy.call(%{
      game: game,
      player_id: player.player_id,
      event_id: event_id
    })
    game = args.game
    player = Enum.at(game.players, 0)
    next_player = Enum.at(game.players, 1)
    assert player.balance == old_balance
    card = Enum.at(game.cards, card_index)
    assert card.owner == nil
    assert game.player_turn == next_player.player_id
    {:error, :no_event} = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :free_card })
    {:error, :no_event} = Event.get_by_type(%{ game: game, player_id: player.player_id, type: :auction })
    event = Event.get_by_type(%{ game: game, player_id: next_player.player_id, type: :auction })
    expected_members = game.players
      |> Enum.filter(fn p -> p.player_id != player.player_id end)
      |> Enum.map(fn p -> p.player_id end)
    assert %Event{} = event
    assert event.amount == card.cost
    assert event.members == expected_members
  end

end
