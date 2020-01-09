defmodule Croc.Pipelines.Games.Monopoly.SingleWinnerGameEnd do
  require Logger
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Repo.Games.Monopoly.Card, as: RepoCard
  alias Croc.Repo.Games.Monopoly.UserCard
  alias Croc.Games.Monopoly
  alias Croc.Repo
  alias Croc.Accounts
  alias Croc.Accounts.User
  alias Croc.Accounts.MonopolyUser
  alias CrocWeb.MonopolyChannel
  alias Croc.Games.Monopoly.Rewards
  alias Croc.Games.Monopoly.Supervisor, as: MonopolySupervisor
  use Opus.Pipeline

  check :last_player_left?, error_message: :has_players
  step :set_player
  step :reset_player_turn
  step :set_ended_time
  step :set_winner
  tee :send_win_event
  tee :broadcast_game_end_event
  step :end_game
  tee :add_exp_to_players
  tee :add_card_reward
  tee :update_users_stats

  def update_users_stats(%{ game: game, player_id: player_id } = args) do
    Enum.each(game.players, fn p ->
      {1, nil} = MonopolyUser.update_user_stats(p.player_id, p.player_id == player_id)
    end)
  end

  def add_card_reward(%{ player_id: player_id } = args) do
    with %{id: id, position: position} <- Rewards.get_random_card() do
      UserCard.add_to_user(player_id, id, position)
    else
      _ ->
        Logger.error("No available reward to give")
    end
  end

  def add_exp_to_players(%{game: game, player_id: player_id} = args) do
    Repo.transaction(fn ->
      results = Enum.map(game.players, fn p ->
        exp_amount =
          case p.player_id == player_id do
            true -> Monopoly.winner_exp_amount() + Monopoly.game_end_exp_amount()
            false -> Monopoly.game_end_exp_amount()
          end
        case Accounts.add_exp(p.player_id, exp_amount) do
          {x, results} when x > 0 and is_list(results) -> %User{} = List.first(results)
          e -> Repo.rollback(e)
        end
      end)
      results
    end)
    |> case do
         {:ok, _results} -> args
         {:error, _reason} = r -> r
       end
  end

  def broadcast_game_end_event(args) do
    :ok = MonopolyChannel.send_game_end_event(args)
  end

  def end_game(args) do
    sleep_time = case Mix.env() do
      :test -> 1
      _ -> 20000
    end
    {:ok, pid} = Task.start(fn ->
      Process.sleep(sleep_time)
      :ok = Monopoly.end_game(args)
    end)
    args
  end

  def last_player_left?(%{ game: game }) do
    players =
      game.players
      |> Enum.filter(fn p -> p.surrender != true end)
    length(players) == 1
  end

  def set_player(%{ game: game } = args) do
    %Player{} = player =
      game.players
      |> Enum.filter(fn p -> p.surrender != true end)
      |> List.first()
    Map.put(args, :player_id, player.player_id)
  end

  def send_win_event(%{ game: game, player_id: player_id }) do
    %Player{name: name} = Player.get(game, player_id)
    MonopolyChannel.send_event(%{ game: game, event: Event.ignored("#{name} побеждает в игре!") })
  end

  def reset_player_turn(%{ game: game } = args) do
    Map.put(args, :game, Map.put(game, :player_turn, nil))
  end

  def set_ended_time(%{ game: game } = args) do
    ended_at = DateTime.utc_now() |> DateTime.truncate(:second)
    Map.put(args, :game, Map.put(game, :ended_at, ended_at))
  end

  def set_winner(%{ game: game, player_id: player_id } = args) do
    Map.put(args, :game, Map.put(game, :winners, [player_id]))
  end
end
