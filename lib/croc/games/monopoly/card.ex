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
    :upgrade_level_payment_amounts,
    upgrade_level: 0
  ]

  def get_all(game, player_id) do
    game.cards
  end

  def get_by_position(game, player_id, position) do
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
