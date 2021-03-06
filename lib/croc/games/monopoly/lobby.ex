defmodule Croc.Games.Monopoly.Lobby do
  alias Croc.Games.Monopoly.{Player, Card}
  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Games.Lobby.Supervisor
  alias Croc.Pipelines.Lobby.SetEventCards
  alias Croc.Repo.Games.Monopoly.{UserCard, UserEventCard}
  require Logger
  use GenServer

  @derive Jason.Encoder
  defstruct [
    :lobby_id,
    :players,
    :options,
    :created_at,
    :chat_id
  ]

  @registry :lobby_registry

  @player_limit 5

  def start_link(state) do
    name = state.lobby.lobby_id
    {:ok, pid} = GenServer.start_link(__MODULE__, state, id: name)
  end

  @impl true
  def init(%{lobby: lobby} = state) do
    name = lobby.lobby_id
    {:ok, _pid} = Registry.register(@registry, name, state)
    {:ok, %{lobby: lobby}}
  end

  def update_lobby_state(%__MODULE__{ lobby_id: lobby_id } = lobby, state) do
    {%{ lobby: _ }, %{ lobby: _ }} = Registry.update_value(:lobby_registry, lobby_id, fn _ -> state end)
    :ok = CrocWeb.Endpoint.broadcast("lobby:all", "lobby_update", lobby)
  end

  def check_joinable(%__MODULE__{players: players}) do
    case length(players) do
      x when x >= @player_limit -> {:error, :maximum_players}
      x when is_integer(x) ->
        :ok
    end
  end

  @impl true
  def handle_call({:join, player_id}, from, %{lobby: lobby} = state) do
    with false <- LobbyPlayer.already_in_lobby?(player_id),
         :ok <- check_joinable(lobby) do
      {:ok, player} = LobbyPlayer.create(player_id, lobby.lobby_id)

      updated_lobby = Map.put(lobby, :players, lobby.players ++ [player])
      updated_state = Map.put(state, :lobby, updated_lobby)
      update_lobby_state(updated_lobby, updated_state)
      {:reply, {:ok, updated_lobby}, updated_state}
    else
      true -> {:reply, {:error, :already_in_lobby}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:leave, player_id}, from, %{lobby: lobby} = state) do
    with true <- LobbyPlayer.in_lobby?(player_id, lobby) do
      updated_lobby =
        Map.put(lobby, :players, Enum.filter(lobby.players, fn p -> p.player_id != player_id end))

      updated_state = Map.put(state, :lobby, updated_lobby)
      update_lobby_state(updated_lobby, updated_state)
      player = Enum.find(lobby.players, fn p -> p.player_id == player_id end)
      :ok = LobbyPlayer.delete_by_id(player.id)
      {:reply, {:ok, updated_lobby}, updated_state}
    else
      _ -> {:reply, {:error, :not_in_lobby}, state}
    end
  end

  @impl true
  def handle_call({:set_event_cards, player_id, event_cards_ids}, _from, %{ lobby: lobby } = state) do
    event_cards = Enum.map(event_cards_ids, fn id -> %UserEventCard{id: id} end)
    case SetEventCards.call(%{ lobby: lobby, player_id: player_id, event_cards: event_cards }) do
      {:ok, %{lobby: lobby}} ->
        state = Map.put(state, :lobby, lobby)
        update_lobby_state(lobby, state)
        {:reply, {:ok, lobby}, state}
      {:error, pipeline_error} ->
        {:reply, {:error, pipeline_error.error}, state}
    end
  end

  @impl true
  def handle_call({:get}, from, %{lobby: lobby} = state) do
    {:reply, {:ok, lobby}, state}
  end

  def create(player_id, options) do
    with false <- LobbyPlayer.already_in_lobby?(player_id) do
      lobby = %__MODULE__{
        lobby_id: Ecto.UUID.generate(),
        players: [],
        created_at: DateTime.utc_now() |> DateTime.truncate(:second),
        chat_id: Ecto.UUID.generate(),
        options: options
      }

      {:ok, lobby} = Supervisor.create_lobby_process(lobby.lobby_id, %{lobby: lobby})
      {:ok, %__MODULE__{}} = join(lobby.lobby_id, player_id)
    else
      _ -> {:error, :already_in_lobby}
    end
  end

  def join(lobby_id, player_id) do
    with {:ok, lobby, pid} <- get(lobby_id) do
      GenServer.call(pid, {:join, player_id})
    else
      e -> e
    end
  end

  def set_event_cards(lobby_id, player_id, event_cards_ids) do
    with {:ok, lobby, pid} <- get(lobby_id) do
      GenServer.call(pid, {:set_event_cards, player_id, event_cards_ids})
    else
      e -> e
    end
  end

  def leave(lobby_id, player_id) do
    with {:ok, lobby, pid} <- get(lobby_id) do
      GenServer.call(pid, {:leave, player_id})
    else
      e -> e
    end
  end

  def get(lobby_id) when lobby_id != nil do
    Registry.lookup(@registry, lobby_id)
    |> case do
      [] ->
        {:error, :no_lobby}

      processes ->
        {pid, init_lobby} = List.first(processes)

        with {:ok, %__MODULE__{} = lobby} <- GenServer.call(pid, {:get}, 5000) do
          {:ok, lobby, pid}
        else
          e ->
            e
            |> IO.inspect(label: "Probably a error at get by lobby id")
        end
    end
  end

  def get_all() do
    Registry.select(:lobby_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.map(fn {key, pid, %{ lobby: lobby }} -> lobby end)
  end

  def has_lobby?(lobby_id) when lobby_id == nil, do: false

  def has_lobby?(lobby_id) do
    {:ok, lobby} = get(lobby_id)
    lobby != nil
  end

  def has_players?(lobby_id) when lobby_id == nil, do: false

  def has_players?(lobby_id) do
    with {:ok, lobby, pid} when lobby != nil <- get(lobby_id) do
      players = lobby.players

      # Если игроков 2 и более, значит лобби может стартовать
      length(players) > 1
    else
      _ -> false
    end
  end

  def delete(lobby_id) when lobby_id != nil do
    Memento.transaction(fn ->
      Memento.Query.delete(__MODULE__, lobby_id)
    end)
  end

  def get_players(lobby_id) do
    {:ok, lobby, pid} = get(lobby_id)
    {:ok, lobby.players}
  end
end
