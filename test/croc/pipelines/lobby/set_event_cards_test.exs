defmodule Croc.PipelinesTest.Lobby.SetEventCardsTest do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Lobby.Player, as: LobbyPlayer
  alias Croc.Pipelines.Lobby.SetEventCards
  alias Croc.Games.Monopoly
  alias Croc.Repo
  alias Croc.Repo.Games.Monopoly.{
    EventCard,
    UserEventCard
  }
  alias Croc.Accounts
  alias Croc.Accounts.User



  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Croc.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Croc.Repo, {:shared, self()})
    end

    players_ids = 1..5
    |> Enum.map(fn x ->
      {:ok, user} = Accounts.create_user(%{ email: "s#{x}@kokoro.codes", username: "zab", password: "somepassword" })
      user
    end)
    |> Enum.map(fn x -> x |> Map.fetch!(:id) end)
    {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

    Enum.slice(players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
    end)
    event_cards = [
      EventCard.create(%{
        name: "Sell loan",
        description: "Desc",
        rarity: 0,
        type: :force_sell_loan,
        image_url: "Some image"
      }),
      EventCard.create(%{
        name: "Auction",
        description: "Desc",
        rarity: 0,
        type: :force_auction,
        image_url: "Some image"
      }),
      EventCard.create(%{
        name: "Teleportation",
        description: "Desc",
        rarity: 0,
        type: :force_teleportation,
        image_url: "Some image"
      })
    ]
    %{
      lobby: lobby,
      players_ids: players_ids,
      event_cards: event_cards
    }
  end

  describe "Set event cards" do
    setup %{ lobby: lobby, event_cards: event_cards } = context do
      player = List.first(lobby.players)
      user_event_cards = Enum.map(event_cards, fn c ->
        {:ok, card} = UserEventCard.create(%{ monopoly_event_card_id: c.id, user_id: player.player_id })
        card
      end)
      Map.put(context, :user_event_cards, user_event_cards)
    end

    test "should throw error if player is not in lobby", %{ lobby: lobby, user_event_cards: user_event_cards } do
      {:error, pipeline_error} = SetEventCards.call(%{
        lobby: lobby,
        player_id: Enum.random(100000..100100),
        event_cards: user_event_cards
      })
      assert pipeline_error.error == :not_in_lobby
    end

    test "should throw error when user event cards is > than limit", %{ lobby: lobby, user_event_cards: user_event_cards } do
      %LobbyPlayer{} = player = List.first(lobby.players)
      not_existing_card_id = 999999
      assert Enum.all?(user_event_cards, fn c -> c.monopoly_event_card_id != not_existing_card_id end)
      {:error, pipeline_error} = SetEventCards.call(%{
        lobby: lobby,
        player_id: player.player_id,
        event_cards: user_event_cards ++ [%UserEventCard{user_id: player.player_id, monopoly_event_card_id: not_existing_card_id}]
      })
      assert pipeline_error.error == :too_many_cards
    end

    test "should throw error when has cards that not exist at user", %{ lobby: lobby, user_event_cards: user_event_cards } do
      %LobbyPlayer{} = player = List.first(lobby.players)
      not_existing_user_card_id = 999999
      assert Enum.all?(user_event_cards, fn c -> c.id != not_existing_user_card_id end)
      {:error, pipeline_error} = SetEventCards.call(%{
        lobby: lobby,
        player_id: player.player_id,
        event_cards: Enum.slice(user_event_cards, 1, 5) ++ [%UserEventCard{List.first(user_event_cards) | id: not_existing_user_card_id}]
      })
      assert pipeline_error.error == :no_such_user_cards
    end

    test "should successfully add cards", %{ lobby: lobby, user_event_cards: user_event_cards } do
      %LobbyPlayer{} = player = List.first(lobby.players)
      {:ok, args} = SetEventCards.call(%{
        lobby: lobby,
        player_id: player.player_id,
        event_cards: user_event_cards
      })
    end
  end

end
