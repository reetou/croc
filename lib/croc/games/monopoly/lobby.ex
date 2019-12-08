defmodule Croc.Games.Monopoly.Lobby do
  alias Croc.Games.Monopoly.{Player, Card}
  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Games.Lobby.Supervisor
  require Logger
  use GenServer

  defstruct [
    :lobby_id,
    :players,
    :options
  ]

  @registry Croc.Games.Registry.Lobby

  @impl true
  def init(%{ lobby: lobby } = state) do
    name = lobby.lobby_id
    {:ok, _pid} = Registry.register(@registry, name, state)
    {:ok, %{ lobby: lobby }}
  end

  @impl true
  def handle_call({:join, player_id}, from, %{ lobby: lobby } = state) do
    with false <- LobbyPlayer.already_in_lobby?(player_id) do
      {:ok, player} = Memento.transaction(fn ->
        player = %LobbyPlayer{player_id: player_id, lobby_id: lobby.lobby_id}
        Memento.Query.write(player)
      end)
      updated_lobby = Map.put(lobby, :players, lobby.players ++ [player])
      updated_state = Map.put(state, :lobby, updated_lobby)
      {:reply, {:ok, updated_lobby}, updated_state}
    else
      e -> {:reply, {:error, :already_in_lobby}, state}
    end
  end

  @impl true
  def handle_call({:leave, player_id}, from, %{ lobby: lobby } = state) do
    with true <- LobbyPlayer.in_lobby?(player_id, lobby) do
      updated_lobby = Map.put(lobby, :players, Enum.filter(lobby.players, fn p -> p.player_id != player_id end))
      updated_state = Map.put(state, :lobby, updated_lobby)
      {:reply, {:ok, updated_lobby}, updated_state}
    else
      _ -> {:reply, {:error, :not_in_lobby}, state}
    end
  end

  @impl true
  def handle_call({:get}, from, %{ lobby: lobby } = state) do
    {:reply, {:ok, lobby}, state}
  end

  def create(player_id, options) do
    with false <- LobbyPlayer.already_in_lobby?(player_id) do
      lobby = %__MODULE__{
        lobby_id: Ecto.UUID.generate,
        players: [],
        options: options
      }
      {:ok, lobby} = Supervisor.create_lobby_process(lobby.lobby_id, %{ lobby: lobby })
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
        [] -> {:error, :no_lobby}
        processes ->
          {pid, init_lobby} = List.first(processes)
          with {:ok, %__MODULE__{} = lobby} <- GenServer.call(pid, {:get}, 5000) do
            {:ok, lobby, pid}
          else
            e -> e
            |> IO.inspect(label: "Probably a error at get by lobby id")
          end
       end
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
