defmodule Croc.PipelinesTest.Games.Monopoly.Roll do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Roll

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

  test "should roll successfully", %{ game: game } do
    player = Enum.at(game.players, 0)
    %Event{event_id: event_id} = event = Event.get_by_type(game, player.player_id, :roll)
    #      game = Map.put(game, :cards, [])
    assert event != nil
    assert game.player_turn == player.player_id
    {:ok, args} = Roll.call(%{
      game: game,
      player_id: player.player_id,
      event_id: event_id
    })
    game = args.game
    event = args.event
    assert args.game != nil
    assert args.event != nil
    player = Enum.at(game.players, 0)
    unless length(player.events) > 0 do
      assert game.player_turn != player.player_id
    end
    assert event != nil
    roll_event = Enum.find(player.events, fn e -> e.type == :roll end)
    assert roll_event == nil
  end


end
