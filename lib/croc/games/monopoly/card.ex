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

  defstruct [
    :id,
    :name,
    :payment_amount,
    :type,
    :position,
    :owner,
    :monopoly_type,
    :on_loan,
    :loan_amount,
    :buyout_amount,
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

  def total_cost(%__MODULE__{type: :payment} = card), do: card.payment_amount

  def total_cost(%__MODULE__{} = card), do: 0

  def get_payment_amount_for_event(%__MODULE__{} = card) do
    case card.type do
      :payment ->
        card.payment_amount

      :brand ->
        multiplier =
          if card.upgrade_level == 0,
            do: 1,
            else: get_upgrade_level_multiplier(card)

        (card.payment_amount * multiplier)
        |> Decimal.new()
        |> Decimal.to_integer()

      _ ->
        0
    end
  end

  def get_upgrade_level_multiplier(%__MODULE__{type: :brand} = card) do
    Enum.at(card.upgrade_level_multipliers, card.upgrade_level - 1)
    |> Decimal.new()
    |> IO.inspect(label: "Decimal is")
    |> Decimal.round(2)
    |> Decimal.to_float()
    |> case do
      x when x < 1 -> 1
      x -> x
    end
  end

  def get_upgrade_level_multiplier(%__MODULE__{} = card), do: 1

  def upgrade(game, player_id, card_id) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card_id end)
    player_index = Enum.find_index(game.players, fn p -> p.player_id == player_id end)
    card = game.cards |> Enum.at(card_index)
    player = game.players |> Enum.at(player_index)

    cond do
      card == nil ->
        {:error, "Unknown card in game"}

      card.owner == nil ->
        {:error, "Card has no owner"}

      card.type != :brand ->
        {:error, "Card is not a brand, cannot level up"}

      card.owner != player_id ->
        {:error, "Provided player id [#{player_id}] is not an owner for this card"}

      player == nil ->
        {:error, "Unknown player in game"}

      player.balance < card.upgrade_cost ->
        {:error, "Not enough money to upgrade"}

      card.max_upgrade_level <= card.upgrade_level ->
        {:error, "Card upgrade level already at maximum"}

      true ->
        new_upgrade_level = card.upgrade_level + 1

        updated_card = %__MODULE__{
          card
          | upgrade_level: new_upgrade_level,
            payment_amount:
              Enum.at(card.upgrade_level_payment_amounts, new_upgrade_level, card.payment_amount)
        }

        updated_player = %Player{player | balance: player.balance - card.upgrade_cost}

        {:ok,
         %Monopoly{
           game
           | players:
               game.players
               |> List.insert_at(player_index, updated_player),
             cards: game.cards |> List.insert_at(card_index, updated_card)
         }}
    end
  end
end
