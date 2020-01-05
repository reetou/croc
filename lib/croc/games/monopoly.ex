defmodule Croc.Games.Monopoly do
  alias Croc.Games.Monopoly.{
    Player,
    Lobby,
    Card,
    Event,
    EventCard
  }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Repo.Games.Monopoly.Card, as: MonopolyCard
  alias Croc.Repo.Games.Monopoly.UserEventCard
  alias Croc.Repo
  import Ecto.Query
  alias Croc.Games.Monopoly.Supervisor, as: MonopolySupervisor
  alias Croc.Games.Lobby.Supervisor, as: LobbySupervisor
  import CrocWeb.Gettext
  alias Croc.Pipelines.Games.Monopoly.{
    Roll,
    Pay,
    Buy,
    RejectBuy,
    AuctionBid,
    AuctionReject,
    Upgrade,
    Downgrade,
    PutOnLoan,
    Buyout,
    Surrender,
    EventCards.ForceAuction,
    EventCards.ForceSellLoan,
    EventCards.ForceTeleportation
  }
  alias Croc.Pipelines.Games.Monopoly.Events.{
    CreatePlayerTimeout
  }
  use GenServer
  require Logger

  @registry :monopoly_registry

  @players_colors [
    "red",
    "yellow",
    "blue",
    "green",
    "aquamarine",
    "grey",
    "brown"
  ]

  @positions Enum.to_list(0..39)

  @enforce_keys [
    :game_id,
    :players,
    :cards,
    :started_at,
    :player_turn
  ]

  @default_round_data %{
    upgrades: [],
    picked_event_cards: []
  }

  @derive {Jason.Encoder, except: [:round_data, :picked_event_cards]}
  defstruct [
    :game_id,
    :players,
    :started_at,
    :ended_at,
    :winners,
    :player_turn,
    :cards,
    :turn_timeout_at,
    :turn_started_at,
    :on_timeout,
    :chat_id,
    round: 1,
    event_cards: [],
    round_data: @default_round_data,
    picked_event_cards: []
  ]

  @game_end_exp_amount 50

  @winner_exp_amount 100

  def turn_timeout(), do: 90000

  def auction_timeout(), do: 20000

  def game_end_exp_amount(), do: @game_end_exp_amount

  def winner_exp_amount(), do: @winner_exp_amount

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
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:force_auction = type, player_id, position}, _from, %{game: game} = state) do
    case ForceAuction.call(%{ game: game, player_id: player_id, type: type, position: position }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:force_teleportation = type, player_id, position}, _from, %{game: game} = state) do
    case ForceTeleportation.call(%{ game: game, player_id: player_id, type: type, position: position }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:force_sell_loan = type, player_id}, _from, %{game: game} = state) do
    case ForceSellLoan.call(%{ game: game, player_id: player_id, type: type }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:put_on_loan, player_id, position}, _from, %{game: game} = state) do
    case PutOnLoan.call(%{ game: game, player_id: player_id, position: position }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:upgrade, player_id, position}, _from, %{game: game} = state) do
    case Upgrade.call(%{ game: game, player_id: player_id, position: position }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:downgrade, player_id, position}, _from, %{game: game} = state) do
    case Downgrade.call(%{ game: game, player_id: player_id, position: position }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:buyout, player_id, position}, _from, %{game: game} = state) do
    case Buyout.call(%{ game: game, player_id: player_id, position: position }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:buy, player_id, event_id}, _from, %{game: game} = state) do
    case Buy.call(%{ game: game, player_id: player_id, event_id: event_id }) do
      {:ok, %{game: game}} ->
        Logger.debug("Processing buy action")
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:reject_buy, player_id, event_id}, _from, %{game: game} = state) do
    case RejectBuy.call(%{ game: game, player_id: player_id, event_id: event_id }) do
      {:ok, %{game: game}} ->
        Logger.debug("Processing buy action")
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:auction_bid, player_id, event_id}, _from, %{game: game} = state) do
    case AuctionBid.call(%{ game: game, player_id: player_id, event_id: event_id }) do
      {:ok, %{game: game}} ->
        Logger.debug("Processing auction bid action")
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        IO.inspect(pipeline_error, label: "Error at bid")
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:auction_reject, player_id, event_id}, _from, %{game: game} = state) do
    case AuctionReject.call(%{ game: game, player_id: player_id, event_id: event_id }) do
      {:ok, %{game: game}} ->
        Logger.debug("Processing auction reject action")
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:pay, player_id, event_id}, _from, %{game: game} = state) do
    case Pay.call(%{ game: game, player_id: player_id, event_id: event_id }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
      x -> IO.inspect(x, label: "X AT PAY")
    end
  end

  @impl true
  def handle_call({:surrender, player_id}, _from, %{game: game} = state) do
    case Surrender.call(%{ game: game, player_id: player_id }) do
      {:ok, %{game: game}} ->
        new_state = Map.put(state, :game, game)
        update_game_state(game, new_state)
        {:reply, {:ok, %{game: game}}, new_state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:get}, _from, %{game: game} = state) do
    {:reply, {:ok, game}, state}
  end

  @impl true
  def handle_call({:update, game}, _from, state) do
    new_state = Map.put(state, :game, game)
    update_game_state(game, new_state)
    IO.inspect(label: "Received update game")
    {:reply, {:ok, game}, new_state}
  end

  @impl true
  def handle_call(params, _from, state) do
    Logger.error("Invalid params at monopoly process call #{inspect params}")
    {:noreply, state}
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
    with {:ok, lobby_players} when length(lobby_players) > 1 <- Lobby.get_players(lobby_id) do
      {:ok, game} =
        Memento.transaction(fn ->
          started_at = DateTime.utc_now() |> DateTime.truncate(:second)
          game_id = Ecto.UUID.generate()
          first_player_id = List.first(lobby_players) |> Map.fetch!(:player_id)
          lobby_players_ids = Enum.map(lobby_players, fn p -> p.player_id end)
          players =
            lobby_players
            |> Enum.map(fn %LobbyPlayer{} = p ->
              events =
                if p.player_id == first_player_id, do: [Event.roll(first_player_id)], else: []
              index = Enum.find_index(lobby_players_ids, fn id -> id == p.player_id end)
              %Player{
                name: p.name,
                player_id: p.player_id,
                game_id: game_id,
                balance: 10000,
                position: 0,
                surrender: false,
                events: events,
                player_cards: [],
                color: Enum.at(@players_colors, index, Enum.at(@players_colors, 0))
              }
            end)

          Enum.each(players, fn p -> Memento.Query.write(p) end)
          event_cards =
            lobby_players
            |> Enum.flat_map(fn p ->
              Enum.map(p.event_cards, fn c ->
                struct(EventCard, Map.from_struct(c.monopoly_event_card))
              end)
            end)
          # Если ивент-карточек в игре нет, не запускаем транзакцию и не удаляем юзер карточки
          unless Enum.empty?(event_cards) do
            event_cards_ids = Enum.flat_map(lobby_players, fn p -> Enum.map(p.event_cards, fn c -> c.id end) end)
            {:ok, _} = Repo.transaction(fn ->
              {deleted_user_cards, _} =
                from(uec in UserEventCard, where: uec.id in ^event_cards_ids)
                |> Repo.delete_all()
              # Если случился какой-то рейс кондишн то отменяем транзакцию и пушим ошибку,
              # чтобы игра не запустилась
              if deleted_user_cards != length(event_cards_ids) do
                Repo.rollback(:deleted_cards_not_match_user_cards)
                raise "Deleted cards not match user cards, aborting start"
              end
            end)
          end
          game = %__MODULE__{
            game_id: game_id,
            players: players,
            started_at: started_at,
            winners: [],
            player_turn: first_player_id,
            chat_id: Ecto.UUID.generate(),
            event_cards: event_cards,
            cards: get_default_cards
          }

          {:ok, %__MODULE__{} = game} = MonopolySupervisor.create_game_process(game.game_id, %{game: game})
#          :ok = CrocWeb.Endpoint.broadcast("lobby:" <> lobby_id, "left", %{ lobby_id: lobby_id })
          :ok = CrocWeb.Endpoint.broadcast("lobby:" <> lobby_id, "game_start", %{ game: game })
          :ok = LobbySupervisor.stop_lobby_process(lobby_id)
          game
        end)

      Enum.each(game.players, fn p ->
        :ok = LobbyPlayer.delete(p.player_id, lobby_id)
      end)
      {:ok, args} = CreatePlayerTimeout.call(%{ game: game, on_timeout: :surrender })
      game = args.game

      {:ok, game}
    else
      e ->
        e
        |> case do
          {:ok, _lobby_players} ->
            {:error, :not_enough_players}
          {:ok, []} ->
            Logger.error("No lobby or no players")
            {:error, :no_players_in_lobby}

          _ ->
            Logger.error("Unknown error")
            {:error, :unknown_error}
        end
    end
  end

  def end_game(%{ game: game }) do
    Memento.transaction(fn ->
      Enum.each(game.players, fn p ->
        :ok = Memento.Query.delete(Player, p.id)
      end)
    end)
    :ok = MonopolySupervisor.stop_game_process(game.game_id)
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
        event = Event.free_card("Попадает на свободное поле #{card.name}", card.position)
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
    |> Enum.sort_by(fn c -> c.position end)
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
    Logger.debug("Processing player turn for from #{player_id} to next")
    with %__MODULE__{} = updated_game <- process_player_turn(game, player_id) do
      Map.put(args, :game, updated_game)
    else
      e -> e
      |> IO.inspect(label: "Error probably at process player turn")
    end
  end

  def process_buy_turn(%{ game: game, player_id: player_id, card: card, amount: amount } = args) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    actual_players = Enum.filter(game.players, fn p -> p.surrender != true and p.balance >= amount end)
    current_player_index = Enum.find_index(actual_players, fn p -> p.player_id == player_id end)
    max_index = length(actual_players) - 1
    next_player_index = if current_player_index + 1 > max_index, do: 0, else: current_player_index + 1
    next_player = Enum.at(actual_players, next_player_index)
    members = Map.get(args, :members, [])
    event = Event.auction(amount, "Думает над поднятием цены за #{card.name}", card.position, player_id, nil, members)
    game = game
           |> Event.add_player_event(next_player.player_id, event)
           |> Map.put(:player_turn, next_player.player_id)
    args
    |> Map.put(:game, game)
    |> Map.put(:event, event)
  end

  def process_player_turn(%__MODULE__{} = game, player_id) do
    player = Player.get(game, player_id)
    Logger.debug("Checking if player #{player_id} not surrendered and 0 events: #{inspect player.events}")
    with true <- length(player.events) == 0 do
      actual_players = Enum.filter(game.players, fn p -> p.surrender != true end)
      current_player_index = Enum.find_index(actual_players, fn p -> p.player_id == player_id end)
      Logger.debug("Current player index #{current_player_index}")
      max_index = length(actual_players) - 1
      unless current_player_index == nil do
        next_player_index = if current_player_index + 1 > max_index, do: 0, else: current_player_index + 1
        next_player = Enum.at(actual_players, next_player_index)
        Logger.debug("Next player gonna be #{next_player.player_id}")
        case next_player_index do
          0 -> game
               |> set_player_turn(next_player.player_id)
               |> change_round()
          _ -> game
               |> set_player_turn(next_player.player_id)
        end
      else
        IO.inspect(actual_players, label: "Looking for #{player_id} in players")
        Logger.error("No such player in game")
        {:error, :no_such_player_in_game}
      end
    else
      _ ->
        game
    end
  end

  def set_player_turn(%__MODULE__{} = game, player_id) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    game = Event.add_player_event(game, player_id, Event.roll(player_id))
    |> Map.put(:player_turn, player_id)
  end

  def change_round(%__MODULE__{} = game) do
    game
    |> Map.put(:round, game.round + 1)
    |> Map.put(:round_data, @default_round_data)
  end

  def update_game_state(%__MODULE__{ game_id: game_id } = game, state) do
    {%{ game: _ }, %{ game: _ }} = Registry.update_value(@registry, game_id, fn _ -> state end)
  end

end
