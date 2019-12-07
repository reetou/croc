defmodule Croc.Games.Monopoly.Lobby do
  alias Croc.Games.Monopoly.{Player}
  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  require Logger

  use Memento.Table,
    attributes: [
      :lobby_id,
      :options
    ],
    type: :ordered_set,
    autoincrement: true

  def create(player_id, options) do
    with false <- LobbyPlayer.already_in_lobby?(player_id) do
      {:ok, lobby} =
        Memento.transaction(fn ->
          players = Memento.Query.select(LobbyPlayer, {:==, :player_id, player_id})

          %__MODULE__{lobby_id: lobby_id} =
            lobby =
            Memento.Query.write(%__MODULE__{
              options: []
            })

          Memento.Query.write(LobbyPlayer.new(player_id, lobby_id))
          Logger.debug("Creating new lobby #{lobby_id} and adding player in it...")
          lobby
        end)
    else
      _ ->
        Logger.error("Already in lobby, cannot create new lobby")
        {:error, :already_in_lobby}
    end
  end

  def join(lobby_id, player_id) do
    with false <- LobbyPlayer.already_in_lobby?(player_id) do
      {:ok, lobby} = Memento.transaction(fn ->
        lobby = Memento.Query.read(__MODULE__, lobby_id)

        unless lobby == nil do
          LobbyPlayer.create(player_id, lobby_id)
        end
      end)

      :ok
    else
      _ ->
        Logger.error("Player #{player_id} is already in lobby, cannot join")
        {:error, :already_in_lobby}
    end
  end

  def leave(lobby_id, player_id) do
    with true <- LobbyPlayer.already_in_lobby?(player_id),
         {:ok, %LobbyPlayer{} = lobby_player} <- LobbyPlayer.get(player_id, lobby_id) do
      {:ok, true} = Memento.transaction(fn ->
        Memento.Query.delete(LobbyPlayer, lobby_player.id)
        players_left = Memento.Query.select(LobbyPlayer, {:==, :lobby_id, lobby_id})
        unless length(players_left) > 0 do
          Memento.Query.delete(__MODULE__, lobby_id)
        end
        true
      end)

      :ok
    else
      _ ->
        Logger.error("Player #{player_id} is not in lobby, cannot leave")
        {:error, :not_in_lobby}
    end
  end

  def get(lobby_id) when lobby_id != nil do
    Memento.transaction(fn ->
      Memento.Query.read(__MODULE__, lobby_id)
    end)
  end

  def has_lobby?(lobby_id) when lobby_id == nil, do: false

  def has_lobby?(lobby_id) do
    {:ok, lobby} = get(lobby_id)
    lobby != nil
  end

  def has_players?(lobby_id) when lobby_id == nil, do: false

  def has_players?(lobby_id) do
    with {:ok, lobby} when lobby != nil <- get(lobby_id) do
      {:ok, players} = get_players(lobby_id)

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
    Memento.transaction(fn ->
      Memento.Query.select(LobbyPlayer, {:==, :lobby_id, lobby_id})
    end)
  end
end
