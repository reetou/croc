defmodule Croc.PipelinesTest.Games.Monopoly.SingleWinnerGameEnd do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Accounts
  alias Croc.Accounts.User
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
    1..100
    |> Enum.each(fn x ->
      Accounts.create_user(%{ email: "fake_user#{x}@game-ender.codes", username: "pwb#{x}", password: "somepassword" })
    end)
    players_ids =
      Enum.take_random(100..180, 5)
      |> Enum.map(fn x ->
        {:ok, user} = Accounts.create_user(%{ email: "s#{x}@zkkzk.codes", username: "pab", password: "somepassword" })
        user
      end)
      |> Enum.map(fn x -> x |> Map.fetch!(:id) end)
    {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

    Enum.slice(players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
    end)

    {:ok, %Monopoly{} = game} = Monopoly.start(lobby)

    %{game: game}
  end


  describe "Add exp to players" do

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

    test "should end game after surrender and add exp to players and a winner", %{ game: game, winner_player: winner_player } do
      old_users = Enum.map(game.players, fn p ->
        %User{} = user = Accounts.get_user!(p.player_id)
      end)
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: game.player_turn
      })
      game = args.game
      assert length(game.winners) == 1
      Enum.each(game.players, fn p ->
        %User{} = user = Accounts.get_user!(p.player_id)
        %User{} = old_user = Enum.find(old_users, fn u -> u.id == p.player_id end)
        exp_amount = if p.player_id in game.winners,
                        do: Monopoly.game_end_exp_amount() + Monopoly.winner_exp_amount(),
                        else: Monopoly.game_end_exp_amount()
        assert user.exp == old_user.exp + exp_amount
      end)
    end
  end
end
