defmodule Croc.Games.Monopoly.Event do
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly
  require Logger

  @derive Jason.Encoder
  defstruct [
    :event_id,
    :type,
    :amount,
    :text,
    :receiver,
    :position,
    :starter,
    :last_bidder,
    priority: 999,
    members: []
  ]

  defp priority(type) do
    case type do
      :pay -> 1
      :auction -> 2
      :free_card -> 3
      :roll -> 100
      _ -> 999
    end
  end

  def new(type) do
    %__MODULE__{
      event_id: Ecto.UUID.generate(),
      type: type,
      priority: priority(type)
    }
  end

  def pay(amount, text, receiver \\ nil) do
    new(:pay)
    |> Map.put(:amount, amount)
    |> Map.put(:text, text)
    |> Map.put(:receiver, receiver)
    |> Map.put(:priority, priority(:pay))
  end

  def ignored(text) do
    new(:noop)
    |> Map.put(:text, text)
  end

  def receive(amount, text) do
    new(:receive)
    |> Map.put(:amount, amount)
    |> Map.put(:text, text)
  end

  def free_card(text, position) do
    new(:free_card)
    |> Map.put(:amount, 0)
    |> Map.put(:text, text)
    |> Map.put(:priority, priority(:free_card))
    |> Map.put(:position, position)
  end

  def roll(player_id) do
    new(:roll)
    |> Map.put(:text, "Ходит")
    |> Map.put(:priority, priority(:roll))
  end

  def auction(amount, text, position, starter_player_id, last_bidder, members \\ []) do
    new(:auction)
    |> Map.put(:text, text)
    |> Map.put(:amount, amount)
    |> Map.put(:position, position)
    |> Map.put(:members, members)
    |> Map.put(:starter, starter_player_id)
    |> Map.put(:last_bidder, last_bidder)
  end

  def get_type(random_event_type) do
    case random_event_type do
      :pay_for_stars -> :pay
      x -> x
    end
  end

  def add_player_event(game, player_id, %__MODULE__{} = event) do
    players =
      Enum.map(game.players, fn p ->
        unless p.player_id != player_id do
          Map.put(p, :events, p.events ++ [event])
        else
          p
        end
      end)

    game
    |> Map.put(:players, players)
  end

  def remove_player_event(%{ game: game, player_id: player_id, event_id: event_id } = args) do
    with %Monopoly{} = result <- remove_player_event(game, player_id, event_id) do
      Map.put(args, :game, result)
    else
      e -> e
    end
  end

  def remove_player_event(game, player_id, event_id) do
    players =
      Enum.map(game.players, fn p ->
        unless p.player_id != player_id do
          updated_events = Enum.filter(p.events, fn e -> e.event_id != event_id end)
          Map.put(p, :events, updated_events)
        else
          p
        end
      end)

    game
    |> Map.put(:players, players)
  end

  defp process(game, player_id, %__MODULE__{type: type, amount: amount} = event) do
    case type do
      :pay ->
        {add_player_event(game, player_id, event), event}

      :receive ->
        {Player.give_money(%{ game: game, player_id: player_id, amount: amount }) |> Map.fetch!(:game), event}

      _ ->
        {game, Map.put(event, :amount, 0)}
    end
  end

  def generate_random(game, player_id) do
    random_event_type = Enum.random([:pay, :receive, :pay_for_stars])
    event_amount = amount(random_event_type, game, player_id)
    type = get_type(random_event_type)

    event =
      new(type)
      |> Map.put(:amount, event_amount)
      |> Map.put(:text, text_for_random_event(random_event_type, event_amount))

    process(game, player_id, event)
  end

  defp amount(:pay, game, player_id) do
    Enum.random([500, 1000])
  end

  defp amount(:receive, game, player_id) do
    Enum.random([250, 750])
  end

  def get_by_type(%{ game: game, player_id: player_id, type: type }) do
    get_by_type(game, player_id, type)
  end

  def has_by_type?(%{ game: game, player_id: player_id, type: type }) do
    case get_by_type(game, player_id, type) do
      %__MODULE__{} -> true
      {:error, _reason} = e -> e
    end
  end

  def get_by_type(game, player_id, type) do
    with %Player{} = player <- Enum.find(game.players, fn p -> p.player_id == player_id end),
         %__MODULE__{} = event <- Enum.find(player.events, fn e -> e.type == type end) do
      event
    else
      {:error, reason} = r -> r
      nil -> {:error, :no_event}
      e ->
        IO.inspect(e, label: "Error at get by type")
        {:error, :unknown_error}
    end
  end

  def get_by_id(game, player_id, event_id) do
    with %Player{} = player <- Enum.find(game.players, fn p -> p.player_id == player_id end),
         %__MODULE__{} = event <- Enum.find(player.events, fn e -> e.event_id == event_id end) do
      event
    else
      _ -> {:error, :no_event}
    end
  end

  defp amount(:pay_for_stars, game, player_id) do
    cards =
      game.cards
      |> Enum.filter(fn c -> c.owner == player_id end)
      |> Enum.filter(fn c -> c.type == :brand end)
      |> Enum.filter(fn c -> c.upgrade_level > 0 end)

    stars =
      cards
      |> Enum.filter(fn c -> c.upgrade_level < c.max_upgrade_level end)
      |> Enum.reduce(0, fn c, acc ->
        c.upgrade_level + acc
      end)

    big_stars =
      cards
      |> Enum.filter(fn c -> c.upgrade_level >= c.max_upgrade_level end)
      |> Enum.reduce(0, fn c, acc ->
        c.max_upgrade_level + acc
      end)

    250 * stars + 1000 * big_stars
  end

  def text_for_random_event(:pay, amount) do
    text =
      Enum.random([:pay_for_debt, :pay_for_birthday, :pay_for_neighbor])
      |> Atom.to_string()

    Gettext.gettext(CrocWeb.Gettext, text, %{name: "Player", amount: amount})
  end

  def text_for_random_event(:receive, amount) do
    text =
      Enum.random([:receive_wallet, :receive_salary])
      |> Atom.to_string()

    Gettext.gettext(CrocWeb.Gettext, text, %{name: "Player", amount: amount})
  end

  def text_for_random_event(:pay_for_stars, amount) do
    text =
      Enum.random([:pay_for_stars])
      |> Atom.to_string()

    Gettext.gettext(CrocWeb.Gettext, text, %{name: "Player", amount: amount})
  end
end
