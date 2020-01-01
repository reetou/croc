defmodule Croc.PipelinesTest.Games.Monopoly.Surrender do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    Surrender
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

  describe "Surrender when has player_turn" do
    test "should process player turn to next player", %{ game: game } do
      %Player{} = player = Player.get(game, game.player_turn)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      players_ids = Enum.map(game.players, fn p -> p.player_id end)
      %Player{player_id: next_player_id} = Enum.at(game.players, player_index + 1, Enum.at(game.players, 0))
      %Event{} = event = Event.get_by_type(game, player.player_id, :roll)
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: player.player_id
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

  describe "Surrender while has no player turn" do
    test "should be surrendered and should not influence processing player turn", %{ game: game } do
      %Player{} = player = Enum.at(game.players, 2)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == game.player_turn end)
      players_ids = Enum.map(game.players, fn p -> p.player_id end)
      turn_player = Player.get(game, game.player_turn)
      %Player{player_id: next_player_id} = Enum.at(game.players, player_index + 1, Enum.at(game.players, 0))
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: player.player_id
      })
      game = args.game
      turn_player = Player.get(game, game.player_turn)
      assert game.player_turn == turn_player.player_id
      %Player{} = player = Player.get(game, player.player_id)
      assert length(player.events) == 0
      assert player.surrender == true
      %Event{} = event = Event.get_by_type(game, turn_player.player_id, :roll)
    end
  end

  describe "Surrender while has cards" do

    setup %{ game: game } do
      player_owner_index = 2
      %Player{player_id: player_id} = Enum.at(game.players, player_owner_index)
      random_cards = get_random_cards_with_index(game.cards, 2, :brand)
      new_cards = Enum.reduce(random_cards, game.cards, fn {card, index}, acc ->
        List.replace_at(acc, index, Map.put(card, :owner, player_id))
      end)
      assert length(new_cards) == length(game.cards)
      %{
        game: Map.put(game, :cards, new_cards),
        player_id: player_id
      }
    end

    test "should be surrendered and should not influence processing player turn", %{ game: game, player_id: player_id } do
      %Player{} = player = Player.get(game, player_id)
      current_turn_player_index = Enum.find_index(game.players, fn p -> p.player_id == game.player_turn end)
      %Player{player_id: next_player_id} = Enum.at(game.players, current_turn_player_index + 1, Enum.at(game.players, 0))
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: player.player_id
      })
      game = args.game
      %Player{} = player = Player.get(game, player.player_id)
      assert length(player.events) == 0
      assert player.surrender == true
      assert Enum.all?(game.cards, fn c -> c.owner != player.player_id end)
    end
  end

  describe "Surrender with ending game when other players surrendered" do

    setup %{ game: game } do
      winner_player = Enum.at(game.players, 3)
      game =
        game.players
        |> Enum.filter(fn p -> p.player_id != game.player_turn end)
        |> Enum.filter(fn p -> p.player_id != winner_player.player_id end)
        |> Enum.reduce(game, fn p, acc ->
          acc
          |> Player.put(p.player_id, :surrender, true)
        end)
      actual_players = Enum.filter(game.players, fn p -> p.surrender != true end)
      assert length(actual_players) == 2
      assert length(game.players) == 5
      %Player{} = player = Player.get(game, game.player_turn)
      assert player.surrender != true
      %{
        game: game,
        winner_player: winner_player,
      }
    end

    test "should surrender and trigger game end pipeline", %{ game: game, winner_player: winner_player } do
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: game.player_turn
      })
      game = args.game
      assert game.ended_at != nil
      assert game.winners == [winner_player.player_id]
      Memento.transaction(fn ->
        assert Enum.all?(game.players, fn p ->
          result = Memento.Query.read(Player, p.id)
          result == nil
        end)
      end)
      Process.sleep(100)
      {:error, :no_game} = Monopoly.get(game.game_id)
    end
  end

end
