defmodule Croc.Games.Monopoly.Player do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.Card

  @enforce_keys [
    :player_id,
    :game_id
  ]

  @derive Jason.Encoder
  use Memento.Table,
    attributes: [
      :id,
      :player_id,
      :game_id,
      :balance,
      :position,
      :surrender,
      :player_cards,
      :events,
      :color,
      :old_position
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

  def player_cards_cost(%Monopoly{} = game, %__MODULE__{player_id: player_id} = player) do
    game.cards
    |> Enum.filter(fn c -> c.owner == player_id end)
    |> Enum.reduce(0, fn c, acc ->
      total_cost = Card.total_cost(c)
      total_cost + acc
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

  def get(%Monopoly{} = game, player_id) do
    Enum.find(game.players, fn p -> p.player_id == player_id end)
  end

  def replace(%Monopoly{} = game, player_id, %__MODULE__{} = player) do
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
    players = List.replace_at(game.players, player_index, player)
    Map.put(game, :players, players)
  end

  def put(%Monopoly{} = game, player_id, key, value) when is_atom(key) do
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
    player = Enum.at(game.players, player_index)
    |> Map.put(key, value)
    players = List.replace_at(game.players, player_index, player)
    Map.put(game, :players, players)
  end

  def take_money(%{ game: game, player_id: player_id, amount: amount } = args) do
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
    player = Enum.at(game.players, player_index)
    with true <- player.balance >= amount do
      game = replace(game, player_id, Map.put(player, :balance, player.balance - amount))
      Map.put(args, :game, game)
    else
      _ -> {:error, :not_enough_money}
    end
  end

  def give_money(%{ game: game, player_id: player_id, amount: amount } = args) do
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
    player = Enum.at(game.players, player_index)
    with true <- amount > 0 do
      game = replace(game, player_id, Map.put(player, :balance, player.balance + amount))
      Map.put(args, :game, game)
    else
      _ -> {:error, :negative_amount}
    end
  end

  def transfer(%{ game: game, sender_id: sender_id, receiver_id: receiver_id, amount: amount } = args) do
    with true <- amount > 0,
         %{ game: %Monopoly{} = g } <- take_money(%{ game: game, player_id: sender_id, amount: amount }),
         %{ game: %Monopoly{} = updated_game } <- give_money(%{ game: g, player_id: receiver_id, amount: amount }) do
      Map.put(args, :game, updated_game)
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def change_position(%{ game: game, player_id: player_id } = args) do
    {x, y} = Monopoly.roll_dice()
    move_value = x + y
    player = Enum.find(game.players, fn p -> p.player_id == player_id end)
    new_position = Monopoly.get_new_position(game, player.position, move_value)
    game =
      game
      |> put(player_id, :old_position, player.position)
      |> put(player_id, :position, new_position)
    args
    |> Map.put(:dice, {x, y})
    |> Map.put(:game, game)
  end

  def is_playing?(%{ game: %Monopoly{} = game, player_id: player_id }) do
    player = Enum.find(game.players, fn p -> p.player_id == player_id and p.surrender != true end)
    player != nil
  end

  def can_roll?(%{ game: %Monopoly{} = game, player_id: player_id }) do
    can_roll?(game, player_id)
  end

  def can_roll?(%Monopoly{} = game, player_id) do
    with %__MODULE__{events: events} <- get(game, player_id) do
      roll_event = Enum.find(events, fn e -> e.type == :roll end)
      filtered_events = events
      |> Enum.filter(fn e -> e.type != :roll end)
      length(filtered_events) == 0 and roll_event != nil
    else
      _ -> {:error, :no_player}
    end
  end
end
