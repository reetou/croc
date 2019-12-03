defmodule Croc.Games.Monopoly.Player do
  require Logger

  @enforce_keys [
    :player_id,
    :game_id
  ]

  use Memento.Table,
    attributes: [
      :id,
      :player_id,
      :game_id,
      :balance,
      :position,
      :surrender,
      :player_cards
    ],
    index: [:player_id, :game_id],
    autoincrement: true,
    type: :ordered_set

  def create(game_id, player_id) do
    {:ok, player} =
      Memento.transaction(fn ->
        Memento.Query.write(%__MODULE__{
          player_id: player_id,
          game_id: game_id,
          balance: 0,
          position: 0,
          surrender: false
        })
      end)
  end

  def surrender(game_id, id) do
    {:ok} =
      Memento.transaction(fn ->
        nil

        # Тут нужно найти все игры игрока в которых он сейчас присутствует
        # И в которой соответствующий game_id
        # И если он присутствует в этой игре и не сдался, то оформить сдачу
        # И удалить его из таблицы с игроками для этой игры
        # А также освободить все его карточки и договоры из игры
        # И вернуть исходную аренду для всех карточек игрока
        #      Memento.Query.read(__MODULE__, id)
        #      game = Memento.Query.read(__MODULE__, game_id)
        #      player = Enum.find(game.players, fn p -> p.player_id == player_id end)
        # Проверяем что игрок присутствует в игре
        #      player != nil and player.surrender != true and game.player_turn == player_id
        #      Memento.Query.delete(__MODULE__, id)
      end)
  end
end
