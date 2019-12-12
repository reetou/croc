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
  def handle_call({:roll, player_id}, _from, %{game: game} = state) do
    with true <- Player.can_roll?(game, player_id),
         true <- can_send_action?(game, player_id),
         %Event{event_id: event_id} = event <- Event.get_by_type(game, player_id, :roll) do
      {%__MODULE__{} = updated_game, event} = roll(game, player_id, event_id)
      new_state = Map.put(state, :game, updated_game)
      update_game_state(updated_game, new_state)
      {:reply, {:ok, %{game: updated_game, event: event}}, new_state}
    else
      e ->
        reply = e
        |> case do
             {:error, _reason} = r -> r
             false -> {:error, :cannot_roll}
           end
        {:reply, reply, state}
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
      case pay(game, player_id, event_id) do
        {:ok, game} ->
          new_state = Map.put(state, :game, game)
          update_game_state(game, new_state)
          {:reply, {:ok, game}, new_state}
        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
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
                balance: 0,
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

  def pay(game, player_id, event_id) do
    player = game.players
      |> Enum.find(fn p -> p.player_id == player_id end)
    event = Enum.find(player.events, fn e -> e.event_id == event_id end)
    cond do
      event == nil -> {:error, :no_event}
      event.type != :pay -> {:error, :invalid_event_type}
      event.receiver != nil ->
        Player.transfer(game, player_id, event.receiver, event.amount)
        |> case do
             %__MODULE__{} = g -> {:ok, process_player_turn(g, player_id)}
             e -> e
           end
      true ->
        Player.take_money(game, player_id, event.amount)
        |> case do
             %__MODULE__{} = g -> {:ok, process_player_turn(g, player_id)}
             e -> e
           end
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
        {game, Event.free_card("Попадает на свободное поле #{card.name}")}

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
        {Player.give_money(game, player_id, 1000),
         Event.ignored("Попадает на старт и получает на тыщу больше")}

      true ->
        {game, Event.ignored("Ничего не произошло, type: #{Atom.to_string(card.type)}")}
    end
  end

  def format_payload({:position_data, game, player, old_position, new_position}) do
    %Card{} = card = Card.get_by_position(game, new_position)
    foreign_owner = card.owner != nil and card.owner != player.player_id and card.type == :brand
    passed_start = new_position < old_position and card.type != :prison
    start_position_bonus = if card.type == :start, do: 1000, else: 0
    passed_start_bonus = if passed_start, do: 2000, else: 0
    must_pay = foreign_owner or card.type == :payment
    payment_amount = if must_pay, do: Card.get_payment_amount(card), else: 0

    data = %{
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

  def get_all() do
    Registry.select(:monopoly_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.map(fn {key, pid, %{ game: game }} -> game end)
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
