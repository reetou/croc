defmodule Croc.Games.Monopoly do
  alias Croc.Games.Monopoly.{
    Player,
    Lobby,
    Card
  }

  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Repo.Games.Monopoly.Card, as: MonopolyCard

  require Logger

  @positions Enum.to_list(0..39)

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

  def positions, do: @positions

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
          cards: get_default_cards
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

  def can_send_action?(game_id, player_id) when game_id == nil do
    {:error, "Unknown game_id"}
  end

  def can_send_action?(game_id, player_id) when player_id == nil do
    {:error, "Unknown player_id"}
  end

  def can_send_action?(game_id, player_id) do
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
      old_position = player.position
      max_position = Enum.max_by(game.cards, fn c -> c.position end)

      new_position =
        case player.position + move_value do
          x when x > max_position -> x - max_position
          x -> x
        end

      player =
        player
        |> Map.put(:position, new_position)

      players = List.insert_at(game.players, player_index, player)
      game = Map.put(game, :players, players)
      Memento.Query.write(game)
      Memento.Query.write(player)

      unless player == nil do
        {:ok, {game, player, old_position, new_position}}
      else
        {:error, "Player not found in game"}
      end
    end)
    |> case do
      {:ok, {game, player, old_position, new_position}} ->
        true
        process_move(game, player, old_position, new_position)

      {:error, message} ->
        Logger.error(message)
    end
  end

  def process_move(%__MODULE__{} = game, %Player{} = player, old_position, new_position) do
    send_event({:position_data, game, player, old_position, new_position})
  end

  def send_event({:position_data = event, game, player, old_position, new_position}) do
    %Card{} = card = Card.get_by_position(game, new_position)
    foreign_owner = card.owner != nil and card.owner != player.player_id and card.type == :brand
    passed_start = new_position < old_position and card.type != :prison
    start_position_bonus = if card.type == :start, do: 1000, else: 0
    passed_start_bonus = if passed_start, do: 2000, else: 0
    must_pay = foreign_owner or card.type == :payment
    payment_amount = if must_pay, do: Card.get_payment_amount_for_event(card), else: 0

    data = %{
      event: event,
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
end
