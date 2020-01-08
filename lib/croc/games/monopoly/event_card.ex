defmodule Croc.Games.Monopoly.EventCard do
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.{
    Card
  }
  alias Croc.Repo.Games.Monopoly.EventCard, as: RepoEventCard
  require Logger

  @event_cards_types [:force_auction, :force_sell_loan, :force_teleportation]

  @derive {Jason.Encoder, except: [:__meta__]}
  defstruct [
    :name,
    :description,
    :type,
    :caller,
    :image_url,
    rarity: 0,
  ]

  def new(:force_auction = type) do
    %__MODULE__{
      name: "Принудительный аукцион",
      type: type,
      caller: nil
    }
  end

  def new(:force_sell_loan = type) do
    %__MODULE__{
      name: "Принудительная продажа заложенного",
      type: type,
      caller: nil
    }
  end

  def new(:force_teleportation = type) do
    %__MODULE__{
      name: "Принудительная телепортация",
      type: type,
      caller: nil
    }
  end

  def get_cost(%Monopoly{} = game, :force_auction), do: 1000

  def get_cost(%Monopoly{} = game, :force_sell_loan) do
    multiplier = game.cards
    |> Enum.filter(fn c -> c.owner != nil end)
    |> Enum.filter(fn c -> Card.not_in_monopoly?(%{ game: game, card: c }) == true end)
    |> Enum.filter(fn c -> c.on_loan == true end)
    |> length()
    multiplier * 750
  end

  def can_use?(%{ game: %Monopoly{} = game }) do
    game.round >= 10
  end

  def get_cost(%Monopoly{} = game, :force_teleportation) do
    multiplier = game.players
    |> Enum.filter(fn p -> p.surrender != true end)
    |> length()

    unless multiplier == 1 do
      (multiplier - 1) * 1000
    else
      2000
    end
  end

  def has_event_card?(args) do
    case get_by_type(args) do
      %RepoEventCard{} -> true
      _ -> false
    end
  end

  def get_by_type(%{ game: %Monopoly{} = game, type: type } = args) when type in @event_cards_types do
    with %RepoEventCard{} = event_card <- Enum.find(game.event_cards, fn c -> c.type == type end) do
      event_card
    else
      nil ->
        Logger.error("Cannot find event card by type #{type}")
        {:error, :no_available_event_card}
    end
  end

  def mark_used(%{ game: %Monopoly{} = game, player_id: player_id, type: type } = args) when type in @event_cards_types do
    with index when index != nil <- Enum.find_index(game.event_cards, fn ec -> ec.type == type end),
         %RepoEventCard{} = event_card <- Enum.at(game.event_cards, index) do
      game =
        game
        |> Map.put(:event_cards, List.delete_at(game.event_cards, index))
        |> Map.put(:picked_event_cards, game.picked_event_cards ++ Map.put(event_card, :caller, player_id))
      Map.put(args, :game, game)
    else
      nil -> {:error, :no_available_event_card}
    end
  end
end
