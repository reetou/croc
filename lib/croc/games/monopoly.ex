defmodule Croc.Games.Monopoly do
  alias Croc.Games.Monopoly.{
    Player,
    Lobby,
    Card,
    Event
  }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Repo.Games.Monopoly.Card, as: MonopolyCard
  alias Croc.Games.Monopoly.Supervisor, as: MonopolySupervisor
  alias Croc.Games.Lobby.Supervisor, as: LobbySupervisor
  import CrocWeb.Gettext
  alias Croc.Pipelines.Games.Monopoly.Roll
  use GenServer
  require Logger

  @registry :monopoly_registry

  @positions Enum.to_list(0..39)

  @enforce_keys [
    :game_id,
    :players,
    :cards,
    :started_at,
    :player_turn
  ]

  @derive Jason.Encoder
  defstruct [
    :game_id,
    :players,
    :started_at,
    :winners,
    :player_turn,
    :cards
  ]

  def start_link(state) do
    name = state.game.game_id
    {:ok, _pid} = GenServer.start_link(__MODULE__, state, id: name)
  end

  @impl true
  def init(%{game: game} = state) do
    name = game.game_id
    {:ok, _pid} = Registry.register(@registry, name, state)
    {:ok, state}
  end

  @impl true
  def handle_call({:roll, player_id, event_id}, _from, %{game: game} = state) do
    case Roll.call(%{ game: game, player_id: player_id, event_id: event_id }) do
      {:ok, %{game: game, event: event}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game, event: event}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:put_on_loan, player_id, card}, _from, %{game: game} = state) do
    with true <- can_send_action?(game, player_id),
         %Player{} = player <- Player.get(game, player_id),
      {:ok, updated_game, _updated_player} <- Card.put_on_loan(game, player, card) do
      new_state = Map.put(state, :game, updated_game)
      update_game_state(updated_game, new_state)
      {:reply, {:ok, updated_game}, new_state}
    else
      _ -> {:reply, {:error, :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:upgrade, player_id, card}, _from, %{game: game} = state) do
    with true <- can_send_action?(game, player_id),
         %Player{} = player <- Player.get(game, player_id) do
      {:ok, updated_game, _updated_player} = Card.upgrade(game, player, card)
      new_state = Map.put(state, :game, updated_game)
      update_game_state(updated_game, new_state)
      {:reply, {:ok, updated_game}, new_state}
    else
      _ -> {:reply, {:error, :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:downgrade, player_id, card}, _from, %{game: game} = state) do
    with true <- can_send_action?(game, player_id),
         %Player{} = player <- Player.get(game, player_id) do
      {:ok, updated_game, _updated_player} = Card.downgrade(game, player, card)
      new_state = Map.put(state, :game, updated_game)
      update_game_state(updated_game, new_state)
      {:reply, {:ok, updated_game}, new_state}
    else
      _ -> {:reply, {:error, :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:buyout, player_id, card}, _from, %{game: game} = state) do
    with true <- can_send_action?(game, player_id),
         %Player{} = player <- Player.get(game, player_id) do
      {:ok, updated_game, _updated_player} = Card.buyout(game, player, card)
      new_state = Map.put(state, :game, updated_game)
      update_game_state(updated_game, new_state)
      {:reply, {:ok, updated_game}, new_state}
    else
      _ -> {:reply, {:error, :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:buy, player_id, card}, _from, %{game: game} = state) do
    with true <- can_send_action?(game, player_id),
         %Player{} = player <- Player.get(game, player_id) do
      {:ok, updated_game, _updated_player} = Card.buy(game, player, card)
      new_state = Map.put(state, :game, updated_game)
      update_game_state(updated_game, new_state)
      {:reply, {:ok, updated_game}, new_state}
    else
      _ -> {:reply, {:error, :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:pay, player_id, event_id}, _from, %{game: game} = state) do
    with true <- can_send_action?(game, player_id),
         %Player{} = player <- Player.get(game, player_id),
         %Event{} <- Event.get_by_type(game, player_id, :pay),
         %Event{} = event <- Event.get_by_id(game, player_id, event_id) do
      true
    else
      _ -> {:reply, {:error, :not_your_turn}, state}
    end
  end

  @impl true
  def handle_call({:get}, _from, %{game: game} = state) do
    {:reply, {:ok, game}, state}
  end

  def get_new_position(%__MODULE__{} = game, position, move_value) do
      max_position = Enum.max_by(game.cards, fn c -> c.position end) |> Map.fetch!(:position)
      case position + move_value do
        x when x > max_position -> x - max_position - 1
        x -> x
      end
  end

  def roll(game, player_id, event_id) do
    {x, y} = roll_dice
    move_value = x + y
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
    player = Enum.at(game.players, player_index)
    old_position = player.position
    new_position = get_new_position(game, player.position, move_value)

    Logger.debug("New position gonna be #{new_position} while max_position")

    event_index =
      Enum.find_index(player.events, fn e -> e.type == :roll and e.event_id == event_id end)
    updated_events = List.delete_at(player.events, event_index)

    players = List.update_at(game.players, player_index, fn p ->
      p
      |> Map.put(:position, new_position)
      |> Map.put(:events, updated_events)
    end)
    updated_game =
      game
      |> Map.put(:players, players)
      |> process_player_turn(player_id)
    process_position_change(updated_game, player, new_position)
  end

  def positions, do: @positions

  def start(%Lobby{lobby_id: lobby_id, options: options}) do
    with {:ok, lobby_players} when length(lobby_players) > 0 <- Lobby.get_players(lobby_id) do
      {:ok, game} =
        Memento.transaction(fn ->
          started_at = DateTime.utc_now() |> DateTime.truncate(:second)
          game_id = Ecto.UUID.generate()
          first_player_id = List.first(lobby_players) |> Map.fetch!(:player_id)

          players =
            lobby_players
            |> Enum.map(fn %LobbyPlayer{} = p ->
              events =
                if p.player_id == first_player_id, do: [Event.roll(first_player_id)], else: []

              %Player{
                player_id: p.player_id,
                game_id: game_id,
                balance: 10000,
                position: 0,
                surrender: false,
                events: events,
                player_cards: []
              }
            end)

          Enum.each(players, fn p -> Memento.Query.write(p) end)

          game = %__MODULE__{
            game_id: game_id,
            players: players,
            started_at: started_at,
            winners: [],
            player_turn: first_player_id,
            cards: get_default_cards
          }

          {:ok, %__MODULE__{} = game} = MonopolySupervisor.create_game_process(game.game_id, %{game: game})
          :ok = CrocWeb.Endpoint.broadcast("lobby:" <> lobby_id, "left", %{ lobby_id: lobby_id })
          :ok = CrocWeb.Endpoint.broadcast("lobby:" <> lobby_id, "game_start", %{ game: game })
          :ok = LobbySupervisor.stop_lobby_process(lobby_id)
          game
        end)

      Enum.each(game.players, fn p ->
        :ok = LobbyPlayer.delete(p.player_id, lobby_id)
      end)

      {:ok, game}
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

  def can_send_action?(%{ game: game, player_id: player_id }) do
    can_send_action?(game, player_id)
  end

  def can_send_action?(game, player_id) do
    with %Player{} = player <- Enum.find(game.players, fn p -> p.player_id == player_id end) do
      # Проверяем что игрок присутствует в игре, не сдался и сейчас его очередь ходить
      player != nil and player.surrender != true and game.player_turn == player_id
    else
      _err ->
        Logger.error("Player #{player_id} not found in game #{game.game_id}")
        false
    end
  end

  def process_position_change(%{ game: game, player_id: player_id } = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    with {game, event} <- process_position_change(game, player, player.position) do
      args
      |> Map.put(:game, game)
      |> Map.put(:event, event)
    else
      e -> e
    end
  end

  def process_position_change(game, %{player_id: player_id} = player, position) do
    Logger.debug("Looking for card by position #{position}")
    %Card{} = card = Card.get_by_position(game, position)

    cond do
      card.type == :random_event ->
        Event.generate_random(game, player_id)

      card.type == :brand and Card.is_owner?(card, player_id) ->
        {game, Event.ignored("Попадает на свое поле и ничего не платит")}

      card.type == :brand and Card.has_owner?(card, player_id) == false ->
        event = Event.free_card("Попадает на свободное поле #{card.name}")
        {Event.add_player_event(game, player_id, event), event}

      card.type == :brand and Card.has_to_pay?(card, player_id) ->
        event = Event.pay(card.payment_amount, "Попадает на чужое поле и должен заплатить", card.owner)
        game = Event.add_player_event(game, player_id, event)
        {game, event}

      card.type == :payment ->
        event = Event.pay(card.payment_amount, "Должен выплатить")
        game = Event.add_player_event(game, player_id, event)
        {game, event}

      card.type == :jail_cell ->
        {game, Event.ignored("Попал в клеточку")}

      card.type == :prison ->
        {game, Event.ignored("Попадает в тюрьмочку")}

      card.type == :start ->
        {Player.give_money(%{ game: game, player_id: player_id, amount: 1000 }) |> Map.fetch!(:game),
         Event.ignored("Попадает на старт и получает на тыщу больше")}

      true ->
        {game, Event.ignored("Ничего не произошло, type: #{Atom.to_string(card.type)}")}
    end
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

  def get_all() do
    Registry.select(:monopoly_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.map(fn {key, pid, %{ game: game }} -> game end)
  end

  def process_player_turn(%{ game: game, player_id: player_id } = args) do
    with %__MODULE__{} = updated_game <- process_player_turn(game, player_id) do
      Map.put(args, :game, updated_game)
    else
      e -> e
    end
  end

  def process_player_turn(%__MODULE__{} = game, player_id) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    with true <- player.surrender != true and length(player.events) == 0 do
      actual_players = Enum.filter(game.players, fn p -> p.surrender != true end)
      current_player_index = Enum.find_index(actual_players, fn p -> p.player_id == player_id end)
      max_index = length(actual_players) - 1
      unless current_player_index == nil do
        next_player_index = if current_player_index + 1 > max_index, do: 0, else: current_player_index + 1
        next_player = Enum.at(actual_players, next_player_index)
        set_player_turn(game, next_player.player_id)
      else
        {:error, :no_such_player_in_game}
      end
    else
      _ -> game
    end
  end

  def set_player_turn(%__MODULE__{} = game, player_id) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    Event.add_player_event(game, player_id, Event.roll(player_id))
    |> Map.put(:player_turn, player_id)
  end

  def update_game_state(%__MODULE__{ game_id: game_id } = game, state) do
    {%{ game: _ }, %{ game: _ }} = Registry.update_value(@registry, game_id, fn _ -> state end)
  end

end
