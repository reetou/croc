defmodule Croc.PipelinesTest.Games.Monopoly.SingleWinnerGameEnd do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Repo
  alias Croc.Repo.Games.Monopoly.Card, as: RepoCard
  alias Croc.Repo.Games.Monopoly.UserCard
  alias Croc.Accounts
  alias Croc.Accounts.User
  alias Croc.Pipelines.Games.Monopoly.{
    Surrender
  }

  @cards [
    %{
      name: "Some card",
      monopoly_type: :social_networks,
      type: :brand,
      position: 14,
      is_default: false,
      image_url: "some_image",
      loan_amount: 1000,
      buyout_cost: 1200,
      upgrade_cost: 1200,
      payment_amount: 1000,
      rarity: 0,
      upgrade_level_multipliers: [1.5, 1.2],
      max_upgrade_level: 2,
      cost: 1500
    },
    %{
      name: "Some other card",
      monopoly_type: :social_networks,
      type: :brand,
      position: 14,
      is_default: false,
      image_url: "some_image",
      loan_amount: 1000,
      buyout_cost: 1200,
      upgrade_cost: 1200,
      payment_amount: 1000,
      rarity: 0,
      upgrade_level_multipliers: [1.5, 1.2],
      max_upgrade_level: 2,
      cost: 1500
    },
  ]

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

  describe "Card reward" do
    setup %{ game: game } do
      Enum.each(@cards, fn c ->
        {:ok, %RepoCard{}} = RepoCard.create(c)
      end)
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

    test "should end game and give reward to winner", %{ game: game, winner_player: winner_player } do
      %User{} = user =
        Accounts.get_user!(winner_player.player_id)
        |> Repo.preload(:user_monopoly_cards)
      assert length(user.user_monopoly_cards) == 0
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: game.player_turn
      })
      game = args.game
      winner_id = List.first(game.winners)
      assert winner_id == winner_player.player_id
      %User{} = user =
        Accounts.get_user!(winner_player.player_id)
        |> Repo.preload(:user_monopoly_cards)
      assert length(user.user_monopoly_cards) == 1
    end
  end

  describe "Update user stats on game end" do
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

    test "should update user stats", %{ game: game, winner_player: winner_player } do
      old_users = Enum.map(game.players, fn p ->
        %User{} = user = Accounts.get_user!(p.player_id)
        assert user.games == 0
        assert user.games_won == 0
        user
      end)
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: game.player_turn
      })
      game = args.game
      winner_id = List.first(game.winners)
      assert winner_id == winner_player.player_id
      Enum.each(game.players, fn p ->
        %User{} = user = Accounts.get_user!(p.player_id)
        %User{} = old_user = Enum.find(old_users, fn u -> u.id == p.player_id end)
        games_won = if p.player_id in game.winners, do: 1, else: 0
        assert user.games == 1
        assert user.games_won == games_won
      end)
    end
  end
end
