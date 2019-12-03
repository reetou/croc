defmodule Croc.Games.Monopoly do
  alias Croc.Games.Monopoly.{
    Player,
    Lobby,
    Card,
  }
  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer

  require Logger

  @enforce_keys [
    :game_id,
    :players,
    :cards,
    :started_at,
    :player_turn
  ]
  use Memento.Table,
    attributes: [
      :game_id,
      :players,
      :started_at,
      :winners,
      :player_turn,
      :cards
    ],
    type: :ordered_set

  def start(%Lobby{lobby_id: game_id, options: options}) do
    with true <- Lobby.has_lobby?(game_id),
         true <- Lobby.has_players?(game_id) do
      Memento.transaction(fn ->
        started_at = DateTime.utc_now() |> DateTime.truncate(:second)
        {:ok, lobby_players} = Lobby.get_players(game_id)
        players =
          lobby_players
          |> Enum.map(fn %LobbyPlayer{} = p ->
            %Player{
              player_id: p.player_id,
              game_id: game_id,
              balance: 0,
              position: 0,
              surrender: false
            }
          end)

        first_player = List.first(players)

        game = %__MODULE__{
          game_id: game_id,
          players: players,
          started_at: started_at,
          winners: [],
          player_turn: first_player.player_id,
          cards: []
        }

        Memento.Query.write(game)
        Enum.each(players, fn p -> Memento.Query.write(p) end)
        game
      end)
    else
      _ ->
        Logger.error("No lobby or no players")
        {:error, :no_players_or_lobby}
    end
  end

  def roll_dice do
    {Enum.random(1..7), Enum.random(1..7)}
  end

  def can_send_event?(game_id, player_id) when game_id == nil do
    {:error, "Unknown game_id"}
  end

  def can_send_event?(game_id, player_id) when player_id == nil do
    {:error, "Unknown player_id"}
  end

  def can_send_event?(game_id, player_id) do
    Memento.transaction(fn ->
      with %__MODULE__{} = game = Memento.Query.read(__MODULE__, game_id),
           %Player{} = player = Enum.find(game.players, fn p -> p.player_id == player_id end) do
        # Проверяем что игрок присутствует в игре, не сдался и сейчас его очередь ходить
        player != nil and player.surrender != true and game.player_turn == player_id
      else
        _err ->
          Logger.error("Game or player not found in Game #{game_id} and Player #{player_id}")
          false
      end
    end)
  end

  def move(game_id, player_id) do
    {x, y} = roll_dice
    move_value = x + y

    Memento.transaction(fn ->
      %__MODULE__{} = game = Memento.Query.read(__MODULE__, game_id)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
      player = Enum.at(game.players, player_index)
      max_position = Enum.max_by(game.cards, fn c -> c.position end)

      new_position = fn ->
        case player.position + move_value do
          x when x > max_position -> x - max_position
          x -> x
        end
      end

      unless player == nil do
        process_move(game, player, new_position)
      else
        {:error, "Player not found in game"}
      end
    end)
  end

  def process_move(%__MODULE__{} = game, %Player{} = player, new_position) do
    %Card{} = card = Card.get_by_position(game, player.player_id, new_position)

    cond do
      card.type == :brand and card.owner == nil and
          can_afford_card_cost?(game, card, player) == false ->
        # У игрока нет денег на балансе, потому выставляем на аукцион
        true

      card.type == :brand and card.owner == nil and
          can_afford_card_cost?(game, card, player) == true ->
        # У игрока есть деньги на балансе, предлагаем купить
        # confirm_event(game, player, :buy_brand, card.price)
        true

      card.type == :brand and card.owner != nil and card.owner.player_id == player.player_id ->
        # Игрок попал на свое поле, ничего не платит
        true

      card.type == :brand and card.owner != nil ->
        # Предлагаем оплатить аренду
        # confirm_event(game, player, :pay_cost, card.payment_amount)
        # Если у игрока не хватает денег, то предлагаем ему заложить все что есть, если этого хватит,
        # Чтобы оплатить аренду
        # Если и этого не хватит, то предлагаем сдаться
        {:ok, game}

      card.type == :random_event ->
        # Выбираем рандом ивент (пока только отнимаем деньги) и ждем подтверждения
        # Игрок должен заложить свои постройки, если хватает денег, и заплатить
        # Или сдаться
        # Если игрок не ответит за положенное время, то сдача засчитается автоматически
        # При следующем пинге
        # Апи будет примерно таким:
        # confirm_event(game, player, :pay, 400)
        # При event_type == :receive дожидаться ответа игрока не нужно, просто накидываем ему баланс
        # process_event(game, player, :receive, 700)
        true
    end
  end

  def can_afford_card_payment_amount?(%__MODULE__{} = game, %Card{} = card, %Player{} = player) do
    player.balance >= card.payment_amount
  end

  def can_afford_card_cost?(%__MODULE__{} = game, %Card{} = card, %Player{} = player) do
    player.balance >= card.cost
  end

  def player_cards_price(game, player) do
    game.cards
    |> Enum.filter(fn c ->
      c.owner == player.player_id and c.on_bail == false and c.type == :brand
    end)
    |> Enum.map(fn c -> c.cost end)
    |> Enum.sum()
  end

  def buy_spot(game_id, player_id, position) do
  end
end
