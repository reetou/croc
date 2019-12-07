defmodule Croc.Games.Monopoly.Lobby.Player do
  require Logger

  @enforce_keys [
    :player_id,
    :lobby_id
  ]

  use Memento.Table,
    attributes: [
      :id,
      :player_id,
      :lobby_id
    ],
    index: [:player_id, :lobby_id],
    autoincrement: true,
    type: :ordered_set

  def new(player_id, lobby_id), do: %__MODULE__{player_id: player_id, lobby_id: lobby_id}

  def create(player_id, lobby_id) do
    Memento.transaction(fn ->
      Memento.Query.write(%__MODULE__{
        player_id: player_id,
        lobby_id: lobby_id
      })
    end)
  end

  def delete(player_id, lobby_id) do
    {:ok} =
      Memento.transaction(fn ->
        lobby_player =
          Memento.Query.select(
            %__MODULE__{
              player_id: player_id,
              lobby_id: lobby_id
            },
            lobby_id
          )
          |> Enum.find(fn p -> p.player_id == player_id end)

        Memento.Query.delete(__MODULE__, lobby_player.id)
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

  def in_lobby?(player_id, lobby_id) do
    {:ok, result} =
      Memento.transaction(fn ->
        guards = [
          {:==, :player_id, player_id},
          {:==, :lobby_id, lobby_id}
        ]

        players = Memento.Query.select(__MODULE__, guards)
        length(players) > 0
      end)
      result
  end
end
