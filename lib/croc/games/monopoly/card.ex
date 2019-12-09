defmodule Croc.Games.Monopoly.Card do
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.{Player}
  require Logger

  @enforce_keys [
    :id,
    :name,
    :position,
    :monopoly_type,
    :type
  ]

  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :payment_amount,
    :raw_payment_amount,
    :type,
    :position,
    :owner,
    :monopoly_type,
    :on_loan,
    :loan_amount,
    :buyout_cost,
    :cost,
    :upgrade_cost,
    :upgrade_level,
    :max_upgrade_level,
    :upgrade_level_multipliers,
    upgrade_level: 0
  ]

  def get_all(game, player_id) do
    game.cards
  end

  def get_by_position(game, position) do
    game.cards
    |> Enum.find(fn c -> c.position == position end)
  end

  def get_all_by_type(game, player_id, type) do
    game.cards
    |> Enum.filter(fn c -> c.type == type end)
  end

  def get_all_by_monopoly_type(game, player_id, monopoly_type) do
    game.cards
    |> Enum.filter(fn c -> c.monopoly_type == monopoly_type end)
  end

  def total_cost(%__MODULE__{type: :brand} = card) do
    card.loan_amount + card.upgrade_cost * card.upgrade_level
  end

  def is_owner?(card, player_id) do
    card.owner == player_id
  end

  def has_owner?(card, player_id) do
    card.owner != nil
  end

  def has_to_pay?(card, player_id) do
    cond do
      card.type != :brand -> false
      card.owner == nil -> false
      card.on_loan == true -> false
      card.owner != player_id -> true
      true -> true
    end
  end

  def total_cost(%__MODULE__{type: :payment} = card), do: card.payment_amount

  def total_cost(%__MODULE__{} = card), do: 0

  def get_payment_amount(%__MODULE__{} = card) do
    case card.type do
      :payment ->
        card.payment_amount

      :brand ->
        multiplier =
          if card.upgrade_level == 0,
            do: 1,
            else: get_upgrade_level_multiplier(card)

        (card.raw_payment_amount * multiplier)
        |> case do
          x when is_float(x) -> Decimal.from_float(x)
          x -> Decimal.new(x)
        end
        |> Decimal.to_integer()

      _ ->
        0
    end
  end

  def get_upgrade_level_multiplier(%__MODULE__{type: :brand} = card) do
    Enum.at(card.upgrade_level_multipliers, card.upgrade_level - 1)
    |> case do
      x when is_float(x) -> Decimal.from_float(x)
      x -> Decimal.new(x)
    end
    |> Decimal.round(2)
    |> Decimal.to_float()
    |> case do
      x when x < 1 -> 1
      x -> x
    end
  end

  def get_upgrade_level_multiplier(%__MODULE__{} = card), do: 1

  def can_upgrade?(
        %Monopoly{} = game,
        %Player{player_id: player_id} = player,
        %__MODULE__{} = card
      ) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)

    cond do
      card_index == nil ->
        {:error, :unknown_game_card}

      player_index == nil ->
        {:error, :unknown_game_player}

      card.owner == nil ->
        {:error, :card_has_no_owner}

      card.type != :brand ->
        {:error, :invalid_card_type}

      card.owner != player_id ->
        {:error, :player_not_owner}

      player.balance < card.upgrade_cost ->
        {:error, :not_enough_money}

      card.max_upgrade_level <= card.upgrade_level ->
        {:error, :max_upgrade_level_reached}

      card.on_loan ->
        {:error, :card_on_loan}

      in_monopoly?(game, player, card) != true ->
        {:error, :no_such_monopoly}

      true ->
        true
    end
  end

  def can_downgrade?(
        %Monopoly{} = game,
        %Player{player_id: player_id} = player,
        %__MODULE__{} = card
      ) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)

    cond do
      card_index == nil ->
        {:error, :unknown_game_card}

      player_index == nil ->
        {:error, :unknown_game_player}

      card.owner == nil ->
        {:error, :card_has_no_owner}

      card.type != :brand ->
        {:error, :invalid_card_type}

      card.owner != player_id ->
        {:error, :player_not_owner}

      card.upgrade_level < 1 ->
        {:error, :upgrade_level_already_at_minimum}

      card.on_loan ->
        {:error, :card_on_loan}

      in_monopoly?(game, player, card) != true ->
        {:error, :no_such_monopoly}

      true ->
        true
    end
  end

  def downgrade(%Monopoly{} = game, %Player{player_id: player_id} = player, %__MODULE__{} = card) do
    with true <- can_downgrade?(game, player, card) do
      card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
      new_upgrade_level = card.upgrade_level - 1

      updated_payment_amount =
        get_payment_amount(%__MODULE__{
          card
          | upgrade_level: new_upgrade_level
        })

      updated_card = %__MODULE__{
        card
        | upgrade_level: new_upgrade_level,
          payment_amount: updated_payment_amount
      }

      updated_player = %Player{player | balance: player.balance + card.upgrade_cost}

      updated_game = %Monopoly{
        game
        | players:
            game.players
            |> List.insert_at(player_index, updated_player),
          cards: game.cards |> List.insert_at(card_index, updated_card)
      }

      {:ok, updated_game, updated_player}
    else
      err ->
        case err do
          {:error, reason} = r ->
            r

          _ ->
            Logger.error("Unknown error at downgrade")
            {:error, :unknown_error}
        end
    end
  end

  def upgrade(%Monopoly{} = game, %Player{player_id: player_id} = player, %__MODULE__{} = card) do
    with true <- can_upgrade?(game, player, card) do
      card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
      new_upgrade_level = card.upgrade_level + 1

      updated_payment_amount =
        get_payment_amount(%__MODULE__{
          card
          | upgrade_level: new_upgrade_level
        })

      updated_card = %__MODULE__{
        card
        | upgrade_level: new_upgrade_level,
          payment_amount: updated_payment_amount
      }

      updated_player = %Player{player | balance: player.balance - card.upgrade_cost}

      updated_game = %Monopoly{
        game
        | players:
            game.players
            |> List.insert_at(player_index, updated_player),
          cards: game.cards |> List.insert_at(card_index, updated_card)
      }

      {:ok, updated_game, updated_player}
    else
      err ->
        case err do
          {:error, reason} = r ->
            r

          _ ->
            Logger.error("Unknown error at upgrade")
            {:error, :unknown_error}
        end
    end
  end

  def in_monopoly?(%Monopoly{} = game, %Player{} = player, %__MODULE__{} = card) do
    game.cards
    |> Enum.filter(fn %__MODULE__{} = c ->
      c.monopoly_type != nil and c.monopoly_type == card.monopoly_type
    end)
    |> Enum.all?(fn %__MODULE__{} = c ->
      c.owner == player.player_id
    end)
  end

  def can_buy?(%Monopoly{} = game, %Player{} = player, %__MODULE__{} = card) do
    cond do
      card.type != :brand -> {:error, :invalid_card_type}
      card.owner == nil -> {:error, :card_has_no_owner}
      card.owner != player.player_id -> {:error, :player_not_owner}
      player.balance < card.cost -> {:error, :not_enough_money}
      card.on_loan == true -> {:error, :on_loan}
      true -> true
    end
  end

  def can_put_on_loan?(%Monopoly{} = game, %Player{} = player, %__MODULE__{} = card) do
    cond do
      card.type != :brand -> {:error, :invalid_card_type}
      card.owner == nil -> {:error, :card_has_no_owner}
      card.owner != player.player_id -> {:error, :player_not_owner}
      card.on_loan == true -> {:error, :already_on_loan}
      true -> true
    end
  end

  def can_buyout?(%Monopoly{} = game, %Player{} = player, %__MODULE__{} = card) do
    cond do
      card.type != :brand -> {:error, :invalid_card_type}
      card.owner == nil -> {:error, :card_has_no_owner}
      card.owner != player.player_id -> {:error, :player_not_owner}
      player.balance < card.buyout_cost -> {:error, :not_enough_money}
      card.on_loan == false -> {:error, :not_on_loan}
      true -> true
    end
  end

  def buyout(%Monopoly{} = game, %Player{position: position} = player, %__MODULE__{} = card) do
    with true <- can_buyout?(game, player, card) do
      card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
      updated_card = %__MODULE__{card | on_loan: false}
      cards = List.insert_at(game.cards, card_index, updated_card)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      player = %Player{player | balance: player.balance - card.buyout_cost}
      players = List.insert_at(game.players, player_index, player)
      game = %Monopoly{game | players: players, cards: cards}
      {:ok, game, player}
    else
      err ->
        case err do
          {:error, reason} = r ->
            r

          _ ->
            Logger.error("Unknown error at buy_building")
            {:error, :unknown_error}
        end
    end
  end

  def buy(%Monopoly{} = game, %Player{position: position} = player, %__MODULE__{} = card) do
    with true <- can_buy?(game, player, card) do
      card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
      updated_card = %__MODULE__{card | owner: player.player_id}
      cards = List.insert_at(game.cards, card_index, updated_card)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      player = %Player{player | balance: player.balance - card.cost}
      players = List.insert_at(game.players, player_index, player)
      game = %Monopoly{game | players: players, cards: cards}
      {:ok, game, player}
    else
      err ->
        case err do
          {:error, reason} = r ->
            r

          _ ->
            Logger.error("Unknown error at buy_building")
            {:error, :unknown_error}
        end
    end
  end

  def put_on_loan(%Monopoly{} = game, %Player{} = player, %__MODULE__{} = card) do
    with true <- can_put_on_loan?(game, player, card) do
      card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
      updated_card = %__MODULE__{card | on_loan: true}
      cards = List.insert_at(game.cards, card_index, updated_card)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      player = %Player{player | balance: player.balance + card.loan_amount}
      players = List.insert_at(game.players, player_index, player)
      game = %Monopoly{game | players: players, cards: cards}
      {:ok, game, player}
    else
      err ->
        case err do
          {:error, reason} = r ->
            r

          _ ->
            Logger.error("Unknown error at buy_building")
            {:error, :unknown_error}
        end
    end
  end
end
