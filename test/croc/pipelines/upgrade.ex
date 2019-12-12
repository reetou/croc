defmodule Croc.PipelinesTest.Games.Monopoly.Upgrade do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.Upgrade

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

  test "should upgrade successfully", %{ game: game } do
    player = Enum.at(game.players, 0)
    assert game.player_turn == player.player_id
    card = Enum.find(game.cards, fn c -> c.type == :brand end)
           |> Map.put(:owner, player.player_id)
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    cards =
      List.replace_at(game.cards, card_index, card)
      |> Enum.map(fn c ->
        unless c.monopoly_type != card.monopoly_type do
          Map.put(c, :owner, player.player_id)
        else
          c
        end
      end)
    game = game
           |> Map.put(:cards, cards)
    old_balance = player.balance
    {:ok, args} = Upgrade.call(%{
      game: game,
      player_id: player.player_id,
      position: card.position
    })
    game = args.game
    player = Enum.at(game.players, 0)
    assert player.balance + card.upgrade_cost == old_balance
    card = Enum.at(game.cards, card_index)
    assert card.upgrade_level == 1
    assert card.payment_amount > card.raw_payment_amount
  end


end
