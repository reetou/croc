defmodule Croc.Games.Monopoly.Lobby.Player do
  alias Croc.Games.Monopoly.Lobby
  alias Croc.Repo
  require Logger

  @enforce_keys [
    :player_id,
    :lobby_id
  ]

  @derive Jason.Encoder
  use Memento.Table,
    attributes: [
      :id,
      :player_id,
      :lobby_id,
      :event_cards
    ],
    index: [:player_id, :lobby_id],
    autoincrement: true,
    type: :ordered_set

  def new(player_id, lobby_id), do: %__MODULE__{player_id: player_id, lobby_id: lobby_id}

  def create(player_id, lobby_id) do
    {:ok, player} = Memento.transaction(fn ->
      Memento.Query.write(%__MODULE__{
        player_id: player_id,
        lobby_id: lobby_id
      })
    end)
  end

  def delete_by_id(id) do
    :ok = Memento.transaction(fn ->
      Memento.Query.delete(__MODULE__, id)
    end)
  end

  def delete(player_id, lobby_id) do
    Memento.transaction(fn ->
      lobby_player =
        Memento.Query.select(__MODULE__, {:==, :lobby_id, lobby_id})
        |> Enum.find(fn p -> p.player_id == player_id end)

      unless lobby_player == nil do
        :ok = Memento.Query.delete(__MODULE__, lobby_player.id)
      else
        :not_found
      end
    end)
  end

  def already_in_lobby?(player_id) do
    {:ok, result} =
      Memento.transaction(fn ->
        players = Memento.Query.select(__MODULE__, {:==, :player_id, player_id})
        length(players) > 0
      end)

    result
  end

  def get_current_lobby_data(player_id) do
    {:ok, result} =
      Memento.transaction(fn ->
        players = Memento.Query.select(__MODULE__, {:==, :player_id, player_id})
        List.first(players)
      end)
  end

  def in_lobby?(player_id, %Lobby{} = lobby) do
    player = Enum.find(lobby.players, fn p -> p.player_id == player_id end)
    result = player != nil

    result
  end

  def get(player_id, lobby_id) do
    {:ok, result} =
      Memento.transaction(fn ->
        guards = [
          {:==, :player_id, player_id},
          {:==, :lobby_id, lobby_id}
        ]

        players = Memento.Query.select(__MODULE__, guards)

        unless length(players) == 0 do
          List.first(players)
        else
          nil
        end
      end)
  end

  def put(%Lobby{} = lobby, player_id, key, value) when is_atom(key) do
    player_index = Enum.find_index(lobby.players, fn p -> p.player_id == player_id end)
    player = Enum.at(lobby.players, player_index)
             |> Map.put(key, value)
    players = List.replace_at(lobby.players, player_index, player)
    Map.put(lobby, :players, players)
  end
end
