defmodule Croc.Games.Monopoly do
  alias Croc.Games.Monopoly.{
    Player,
    Lobby,
    Card
  }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Repo.Games.Monopoly.Card, as: MonopolyCard
  alias Croc.Games.Monopoly.Supervisor, as: MonopolySupervisor
  alias Croc.Games.Lobby.Supervisor, as: LobbySupervisor
  use GenServer
  require Logger

  @registry Croc.Games.Registry.Monopoly

  @positions Enum.to_list(0..39)

  @enforce_keys [
    :game_id,
    :players,
    :cards,
    :started_at,
    :player_turn
  ]

  defstruct [
    :game_id,
    :players,
    :started_at,
    :winners,
    :player_turn,
    :cards
  ]

  @impl true
  def init(%{game: game} = state) do
    name = game.game_id
    {:ok, _pid} = Registry.register(@registry, name, state)
    {:ok, state}
  end

  @impl true
  def handle_call({:move, player_id}, _from, %{game: game} = state) do
    with true <- can_send_action?(game.game_id, player_id) do
      {x, y} = roll_dice
      move_value = x + y
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
      player = Enum.at(game.players, player_index)
      old_position = player.position
      max_position = Enum.max_by(game.cards, fn c -> c.position end)

      new_position =
        case player.position + move_value do
          x when x > max_position -> x - max_position
          x -> x
        end

      player =
        player
        |> Map.put(:position, new_position)

      players = List.insert_at(game.players, player_index, player)
      updated_game = Map.put(game, :players, players)

      process_move(updated_game, player, old_position, new_position)
      {:reply, {:ok, updated_game}, Map.put(state, :game, updated_game)}
    else
      _ -> {:reply, %{error: :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:put_on_loan, %{player: player, card: card}}, _from, %{game: game} = state) do
    with true <- can_send_action?(game.game_id, player.player_id) do
      {:ok, updated_game, _updated_player} = Card.put_on_loan(game, player, card)
      {:reply, {:ok, updated_game}, updated_game}
    else
      _ -> {:reply, %{error: :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:upgrade, %{player: player, card: card}}, _from, %{game: game} = state) do
    with true <- can_send_action?(game.game_id, player.player_id) do
      {:ok, updated_game, _updated_player} = Card.upgrade(game, player, card)
      {:reply, {:ok, updated_game}, updated_game}
    else
      _ -> {:reply, %{error: :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:downgrade, %{player: player, card: card}}, from, %{game: game} = state) do
    with true <- can_send_action?(game.game_id, player.player_id) do
      {:ok, updated_game, _updated_player} = Card.upgrade(game, player, card)
      {:reply, {:ok, updated_game}, updated_game}
    else
      _ -> {:reply, %{error: :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:get}, from, %{game: game} = state) do
    {:reply, {:ok, game}, state}
  end

  def positions, do: @positions

  def start(%Lobby{lobby_id: lobby_id, options: options}) do
    with {:ok, lobby_players} when length(lobby_players) > 0 <- Lobby.get_players(lobby_id) do
      {:ok, game} =
        Memento.transaction(fn ->
          started_at = DateTime.utc_now() |> DateTime.truncate(:second)
          game_id = Ecto.UUID.generate()

          players =
            lobby_players
            |> Enum.map(fn %LobbyPlayer{} = p ->
              %Player{
                player_id: p.player_id,
                game_id: game_id,
                balance: 0,
                position: 0,
                surrender: false
              }
            end)

          Enum.each(players, fn p -> Memento.Query.write(p) end)

          game = %__MODULE__{
            game_id: game_id,
            players: players,
            started_at: started_at,
            winners: [],
            player_turn: List.first(players) |> Map.fetch!(:player_id),
            cards: get_default_cards
          }

          {:ok, game} = MonopolySupervisor.create_game_process(game.game_id, %{game: game})
          LobbySupervisor.stop_lobby_process(lobby_id)

          game
        end)
    else
      e ->
        e
        |> case do
          {:ok, []} ->
            Logger.error("No lobby or no players")
            {:error, :no_players_in_lobby}

          _ ->
            Logger.error("Unknown error")
            {:error, :unknown_error}
        end
    end
  end

  def roll_dice do
    {Enum.random(1..6), Enum.random(1..6)}
  end

  def can_send_action?(game_id, player_id) when game_id == nil do
    {:error, :unknown_game_id}
  end

  def can_send_action?(game_id, player_id) when player_id == nil do
    {:error, :unknown_player_id}
  end

  def can_send_action?(game_id, player_id) do
    with {:ok, %__MODULE__{} = game, pid} = get(game_id),
         %Player{} = player = Enum.find(game.players, fn p -> p.player_id == player_id end) do
      # Проверяем что игрок присутствует в игре, не сдался и сейчас его очередь ходить
      player != nil and player.surrender != true and game.player_turn == player_id
    else
      _err ->
        Logger.error("Game or player not found in Game #{game_id} and Player #{player_id}")
        false
    end
  end

  def move(game_id, player_id) do
    with {:ok, game, pid} <- get(game_id) do
      GenServer.call(pid, {:move, player_id})
    else
      e -> e
    end
  end

  def process_move(%__MODULE__{} = game, %Player{} = player, old_position, new_position) do
    send_event({:position_data, game, player, old_position, new_position})
  end

  def send_event({:position_data = event, game, player, old_position, new_position}) do
    %Card{} = card = Card.get_by_position(game, new_position)
    foreign_owner = card.owner != nil and card.owner != player.player_id and card.type == :brand
    passed_start = new_position < old_position and card.type != :prison
    start_position_bonus = if card.type == :start, do: 1000, else: 0
    passed_start_bonus = if passed_start, do: 2000, else: 0
    must_pay = foreign_owner or card.type == :payment
    payment_amount = if must_pay, do: Card.get_payment_amount_for_event(card), else: 0

    data = %{
      event: event,
      player_id: player.player_id,
      card: card,
      passed_start: passed_start,
      receive_money_bonus_amount: start_position_bonus,
      receive_money_amount: passed_start_bonus,
      can_afford_card_payment_amount: can_afford_card_payment_amount?(card, player),
      must_pay: must_pay,
      payment_amount: payment_amount,
      can_buy: card.owner == nil and card.type == :brand,
      can_afford_buy: player.balance >= card.cost,
      old_position: old_position,
      new_position: new_position,
      game: game
    }
  end

  def can_afford_card_payment_amount?(%Card{} = card, %Player{} = player) do
    player.balance >= card.payment_amount
  end

  def can_afford_card_cost?(%Card{} = card, %Player{} = player) do
    player.balance >= card.cost
  end

  def get_default_cards do
    MonopolyCard.get_default_by_positions(@positions)
  end

  def get(game_id) when game_id != nil do
    Registry.lookup(@registry, game_id)
    |> case do
      [] ->
        {:error, :no_game}

      processes ->
        {pid, _init_game} = List.first(processes)

        with {:ok, %__MODULE__{} = game} <- GenServer.call(pid, {:get}, 5000) do
          {:ok, game, pid}
        else
          e ->
            e
            |> IO.inspect(label: "Probably a error at get by game id")
        end
    end
  end
end
