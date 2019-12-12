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

  def in_monopoly?(%{ game: game, player: player, card: card }) do
    game.cards
    |> Enum.filter(fn %__MODULE__{} = c ->
      c.monopoly_type != nil and c.monopoly_type == card.monopoly_type
    end)
    |> Enum.all?(fn %__MODULE__{} = c ->
      c.owner == player.player_id
    end)
  end

  def downgrade(%{ game: game, player: %Player{player_id: player_id} = player, card: card } = args) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    new_upgrade_level = card.upgrade_level - 1
    new_payment_amount = get_payment_amount(Map.put(card, :upgrade_level, new_upgrade_level))
    card =
      card
      |> Map.put(:upgrade_level, new_upgrade_level)
      |> Map.put(:payment_amount, new_payment_amount)
    game = Map.put(game, :cards, List.replace_at(game.cards, card_index, card))
    args
    |> Map.put(:game, game)
  end

  def upgrade(%{ game: game, player: %Player{player_id: player_id} = player, card: card } = args) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    new_upgrade_level = card.upgrade_level + 1
    new_payment_amount = get_payment_amount(Map.put(card, :upgrade_level, new_upgrade_level))
    card =
      card
      |> Map.put(:upgrade_level, new_upgrade_level)
      |> Map.put(:payment_amount, new_payment_amount)
    game = Map.put(game, :cards, List.replace_at(game.cards, card_index, card))
    args
    |> Map.put(:game, game)
  end

  def buyout(%{ game: game, player: player, card: card } = args) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    updated_card = Map.put(card, :on_loan, false)
    cards = List.replace_at(game.cards, card_index, updated_card)
    game = Map.put(game, :cards, cards)
    Map.put(args, :game, game)
  end

  def buy(%{ game: game, player: player, card: card } = args) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    updated_card = Map.put(card, :owner, player.player_id)
    cards = List.replace_at(game.cards, card_index, updated_card)
    game = Map.put(game, :cards, cards)
    Map.put(args, :game, game)
  end

  def put_on_loan(%{ game: game, card: card, player: player } = args) do
    card_index = Enum.find_index(game.cards, fn c -> c.id == card.id end)
    updated_card = Map.put(card, :on_loan, true)
    cards = List.replace_at(game.cards, card_index, updated_card)
    game = game
           |> Map.put(:cards, cards)
    Map.put(args, :game, game)
  end
end
