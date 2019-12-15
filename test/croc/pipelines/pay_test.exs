defmodule Croc.PipelinesTest.Games.Monopoly.Pay do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Pay

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

  test "should pay successfully", %{ game: game } do
    first_player = Enum.at(game.players, 0)
    index = 2
    third_player = Enum.at(game.players, index)

    cards =
      Enum.map(game.cards, fn c ->
        unless c.type != :brand or c.owner != nil do
          Map.put(c, :owner, first_player.player_id)
        else
          c
        end
      end)

    card = Enum.find(cards, fn c -> c.owner == first_player.player_id end)
    players = Enum.map(game.players, fn p ->
      unless p.player_id != third_player.player_id do
        Map.put(p, :balance, 5000)
      else
        p
      end
    end)
    game = game
           |> Map.put(:cards, cards)
           |> Map.put(:players, players)
           |> Map.put(:player_turn, third_player.player_id)
    third_player = Enum.at(game.players, index)
    {game, _event} = Monopoly.process_position_change(game, third_player, card.position)

    third_player = Enum.at(game.players, index)
    player_event = Enum.find(third_player.events, fn e -> e.type == :pay end)
    assert player_event != nil
    assert player_event.type == :pay
    assert game.player_turn == third_player.player_id
    {:ok, args} = Pay.call(%{
      game: game,
      player_id: third_player.player_id,
      event_id: player_event.event_id
    })
    game = args.game
    event = args.event
    updated_first_player = Enum.at(game.players, 0)
    updated_third_player = Enum.at(game.players, index)
    assert updated_first_player.balance == first_player.balance + player_event.amount
    assert args.game != nil
    assert args.event != nil
    assert game.player_turn != third_player.player_id
    assert updated_third_player.balance == third_player.balance - player_event.amount
    assert event != nil
    pay_event = Enum.find(updated_third_player.events, fn e -> e.event_id == args.event_id end)
    assert pay_event == nil
  end


end
