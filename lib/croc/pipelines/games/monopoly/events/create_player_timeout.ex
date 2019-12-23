defmodule Croc.Pipelines.Games.Monopoly.Events.CreatePlayerTimeout do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    AuctionReject,
    RejectBuy,
    Surrender
  }
  alias Croc.Pipelines.Games.Monopoly.Events.{
    RemovePlayerTimeout
  }
  alias CrocWeb.MonopolyChannel
  require Logger
  use Opus.Pipeline

  check :has_player_turn?, error_message: :no_player_turn
  check :has_timeout_callback?, error_message: :no_timeout_callback

  link RemovePlayerTimeout

  step :set_timeout_callback

  step :create_auction_reject_timeout, if: :auction_reject_callback?

  step :create_surrender_timeout, if: :surrender_callback?

  step :create_reject_buy_timeout, if: :reject_buy_callback?

  tee :send_game_update_event, with: &MonopolyChannel.send_game_update_event/1


  def set_timeout_callback(%{ game: game, on_timeout: on_timeout } = args) do
    Map.put(args, :game, Map.put(game, :on_timeout, on_timeout))
  end

  def has_player_turn?(%{ game: game }) do
    game.player_turn != nil
  end

  def surrender_callback?(%{ on_timeout: on_timeout }) do
    on_timeout == :surrender
  end

  def auction_reject_callback?(%{ on_timeout: on_timeout }) do
    on_timeout == :auction_reject
  end

  def reject_buy_callback?(%{ on_timeout: on_timeout }) do
    on_timeout == :reject_buy
  end

  def create_auction_reject_timeout(%{ game: game } = args) do
    player_id = game.player_turn
    Logger.debug("SCHEDULING auction reject for player #{player_id}")
    %Event{event_id: event_id} = Event.get_by_type(game, player_id, :auction)
    timeout = Monopoly.auction_timeout()
    {:ok, %Monopoly{} = game} = update_game_timeout(game, timeout)
    {:ok, timeout_pid} = start_timeout_task(game, timeout, fn ->
      {:ok, game, pid} = Monopoly.get(game.game_id)
      Logger.debug("Calling auction reject for player #{player_id}")
      {:ok, args} = AuctionReject.call(%{
        game: game,
        player_id: player_id,
        event_id: event_id
      })
      {:ok, %Monopoly{}} = GenServer.call(pid, {:update, args.game})
    end)
    Map.put(args, :game, game)
  end

  def create_surrender_timeout(%{ game: game } = args) do
    timeout = Monopoly.turn_timeout()
    player_id = game.player_turn
    Logger.debug("SCHEDULING surrender for player #{player_id}")
    {:ok, %Monopoly{} = game} = update_game_timeout(game, timeout)
    {:ok, timeout_pid} = start_timeout_task(game, timeout, fn ->
      {:ok, game, pid} = Monopoly.get(game.game_id)
      Logger.debug("Calling surrender for player #{player_id}")
      {:ok, args} = Surrender.call(%{
        game: game,
        player_id: player_id,
      })
      {:ok, %Monopoly{}} = GenServer.call(pid, {:update, args.game})
    end)
    Map.put(args, :game, game)
  end

  def create_reject_buy_timeout(%{ game: game } = args) do
    player_id = game.player_turn
    Logger.error("SCHEDULING reject buy for player #{player_id}")
    %Event{event_id: event_id} = Event.get_by_type(game, player_id, :free_card)
    timeout = Monopoly.auction_timeout()
    {:ok, %Monopoly{} = game} = update_game_timeout(game, timeout)
    {:ok, timeout_pid} = start_timeout_task(game, timeout, fn ->
      {:ok, game, pid} = Monopoly.get(game.game_id)
      Logger.error("Calling reject buy for player #{player_id}")
      {:ok, args} = RejectBuy.call(%{
        game: game,
        player_id: player_id,
        event_id: event_id
      })
      {:ok, %Monopoly{}} = GenServer.call(pid, {:update, args.game})
    end)
    Map.put(args, :game, game)
  end

  def start_timeout_task(%Monopoly{ game_id: game_id, turn_timeout_at: turn_timeout_at, player_turn: player_turn }, timeout, fun) when is_function(fun) do
    Task.start(fn ->
      Process.sleep(timeout)
      {:ok, game, pid} = Monopoly.get(game_id)
      with true <- turn_timeout_at == game.turn_timeout_at,
           true <- player_turn == game.player_turn do
        Logger.debug("Starting task for #{game.turn_timeout_at} and player turn is #{game.player_turn} because its not changed")
        fun.()
        Logger.debug("Function call ended")
      else
        x ->
          Logger.debug("Turn timeout time has changed from #{turn_timeout_at} to #{game.turn_timeout_at}
          OR player_turn changed from #{player_turn} to #{game.player_turn}, ignoring this event")
      end
    end)
  end

  def update_game_timeout(game, timeout) do
    timeout_at =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.add(timeout, :millisecond)
    game =
      game
      |> Map.put(:turn_timeout_at, timeout_at)
    {:ok, game}
  end

  def has_timeout_callback?(args) do
    on_timeout = Map.get(args, :on_timeout, nil)
    on_timeout != nil
  end

end
