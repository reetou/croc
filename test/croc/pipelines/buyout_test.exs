defmodule Croc.PipelinesTest.Games.Monopoly.Buyout do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Buyout

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

  test "should buyout successfully", %{ game: game } do
    player = Enum.at(game.players, 0)
    assert game.player_turn == player.player_id
    card = Enum.find(game.cards, fn c -> c.type == :brand end)
           |> Map.put(:owner, player.player_id)
           |> Map.put(:on_loan, true)
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    game = game
           |> Map.put(:cards, List.replace_at(game.cards, card_index, card))
    old_balance = player.balance
    {:ok, args} = Buyout.call(%{
      game: game,
      player_id: player.player_id,
      position: card.position
    })
    game = args.game
    player = Enum.at(game.players, 0)
    assert player.balance == old_balance - card.buyout_cost
    card = Enum.at(game.cards, card_index)
    assert card.on_loan == false
  end


end
