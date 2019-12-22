defmodule Croc.GamesTest.MonopolyTest do
  use ExUnit.Case

  alias Croc.Games.{
    Monopoly,
    Monopoly.Player,
    Monopoly.Lobby,
    Monopoly.Event
  }

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Croc.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Croc.Repo, {:shared, self()})
    end

    players_ids = Enum.take_random(1..999_999, 5)
    {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

    Enum.slice(players_ids, 1, 100)
    |> Enum.each(fn player_id ->
      {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
    end)

    {:ok, lobby_players} = Lobby.get_players(lobby.lobby_id)

    %{
      lobby: lobby,
      lobby_players: lobby_players,
      players_ids: players_ids
    }
  end

  test "should start game for lobby and write game data to mnesia", context do
    {:ok, %Monopoly{} = game} = Monopoly.start(context.lobby)

    assert context.lobby.lobby_id != game.game_id
    assert length(context.players_ids) == length(game.players)

    assert Enum.all?(game.players, fn p ->
             assert Enum.member?(context.players_ids, p.player_id)
             p.game_id == game.game_id
           end)

    assert length(game.cards) > 0

    {:ok, _result} =
      Memento.transaction(fn ->
        players = Memento.Query.select(Player, {:==, :game_id, game.game_id})

        assert Enum.all?(players, fn p ->
                 Enum.member?(context.players_ids, p.player_id)
               end)

        assert length(players) == length(context.players_ids)
      end)
  end

  describe "roll event" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

      Enum.slice(players_ids, 1, 100)
      |> Enum.each(fn player_id ->
        {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
      end)

      {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
      %{game: game}
    end

    test "should have players turn on start", %{game: game} do
      %Player{player_id: player_id} = player = Enum.at(game.players, 0)
      assert game.player_turn == player_id
      event = Enum.find(player.events, fn e -> e.type == :roll end)
      assert length(player.events) == 1
      assert event != nil
    end

    test "should successfully send roll event", %{game: game} do
      %Player{player_id: player_id} = player = Enum.at(game.players, 0)
      %Player{} = next_player = Enum.at(game.players, 1)
      assert game.player_turn == player_id
      player_roll_event = Event.get_by_type(game, player_id, :roll)
      assert player_roll_event != nil
      {:ok, game, pid} = Monopoly.get(game.game_id)
      {:ok, %{game: updated_game}} = GenServer.call(pid, {:roll, player_id, player_roll_event.event_id})
      updated_player = Enum.at(updated_game.players, 0)
      assert is_list(updated_player.events)
      event = Event.get_by_type(updated_game, player_id, :roll)
      assert event == {:error, :no_event}
      if length(updated_player.events) == 0 do
        assert updated_game.player_turn == next_player.player_id
      end
      assert updated_player.player_id == player.player_id
      assert updated_player.position != player.position
    end

    test "should throw error if player has no roll event", %{game: game} do
      %Player{player_id: player_id} = Enum.at(game.players, 2)
      {:error, :no_event} = Event.get_by_type(game, player_id, :roll)
      assert game.player_turn != player_id
      {:ok, game, pid} = Monopoly.get(game.game_id)
      {:error, :no_roll_event} = GenServer.call(pid, {:roll, player_id, "123"})
    end

    test "should throw error if player is not in game", %{game: game} do
      player_id = Enum.random(999999..1300000)
      {:ok, game, pid} = Monopoly.get(game.game_id)
      {:error, :no_player} = GenServer.call(pid, {:roll, player_id, "123"})
    end
  end

  describe "get cards" do
    test "should get default cards" do
      cards = Monopoly.get_default_cards()
      assert length(cards) == 40
      unique_by_position = Enum.uniq_by(cards, fn c -> c.position end)
      assert length(cards) == length(unique_by_position)

      assert Enum.all?(Monopoly.positions(), fn position ->
               result = cards |> Enum.filter(fn c -> c.position == position end)
               assert length(result) == 1
             end)
    end
  end

  describe "process position change" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

      Enum.slice(players_ids, 1, 100)
      |> Enum.each(fn player_id ->
        {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
      end)

      {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
      %{game: game}
    end

    test "should process card type == start and give 1000k to player", %{game: game} do
      player = Enum.at(game.players, 0)
      position = Enum.find(game.cards, fn c -> c.type == :start end) |> Map.fetch!(:position)
      {updated_game, _event} = Monopoly.process_position_change(game, player, position)
      updated_player = Enum.at(updated_game.players, 0)
      assert updated_player.player_id == player.player_id
      assert updated_player.balance == player.balance + 1000
    end

    test "should process card type == payment and player event with type :pay", %{game: game} do
      index = 2
      player = Enum.at(game.players, index)
      card = Enum.find(game.cards, fn c -> c.type == :payment end)
      position = card |> Map.fetch!(:position)
      {updated_game, _event} = Monopoly.process_position_change(game, player, position)
      updated_player = Enum.at(updated_game.players, index)
      assert updated_player.player_id == player.player_id
      assert updated_player.balance == player.balance
      assert length(updated_player.events) == 1
      event = Enum.find(updated_player.events, fn e -> e.type == :pay end)
      assert event != nil
      assert event.amount == card.payment_amount
    end

    test "should process stepping on free card and receive free_card event", %{game: game} do
      index = 2
      player = Enum.at(game.players, index)
      card = Enum.find(game.cards, fn c -> c.type == :brand end)
      position = card |> Map.fetch!(:position)
      {updated_game, game_event} = Monopoly.process_position_change(game, player, position)
      assert game_event.type == :free_card
      updated_player = Enum.at(updated_game.players, index)
      assert updated_player.player_id == player.player_id
      assert updated_player.balance == player.balance
      assert length(updated_player.events) == 1
    end

    test "should process stepping on other player's card", %{game: game} do
      first_player = Enum.at(game.players, 0)
      index = 2
      third_player = Enum.at(game.players, index)

      cards =
        Enum.map(game.cards, fn c ->
          unless c.type != :brand or c.owner != nil do
            Map.put(c, :owner, first_player.player_id)
          else
            c
          end
        end)

      card = Enum.find(cards, fn c -> c.owner == first_player.player_id end)
      game = Map.put(game, :cards, cards)
      {updated_game, event} = Monopoly.process_position_change(game, third_player, card.position)
      updated_player = Enum.at(updated_game.players, index)
      assert updated_player.player_id == third_player.player_id
      assert updated_player.balance == third_player.balance
      assert updated_player.balance == first_player.balance
      assert length(updated_player.events) == 1
      player_event = Enum.find(updated_player.events, fn e -> e.type == :pay end)
      assert event == player_event
      assert event != nil
      assert event.type == :pay
      assert event.amount == card.payment_amount
    end

    test "should process stepping on own card", %{game: game} do
      index = 2
      player = Enum.at(game.players, index)

      cards =
        Enum.map(game.cards, fn c ->
          unless c.type != :brand or c.owner != nil do
            Map.put(c, :owner, player.player_id)
          else
            c
          end
        end)

      card = Enum.find(cards, fn c -> c.owner == player.player_id end)
      game = Map.put(game, :cards, cards)
      {updated_game, event} = Monopoly.process_position_change(game, player, card.position)
      assert event.type == :noop
      updated_player = Enum.at(updated_game.players, index)
      assert updated_player.balance == player.balance
      assert length(updated_player.events) == 0
      event = Enum.find(updated_player.events, fn e -> e.type == :pay end)
      assert event == nil
    end

    test "should process stepping on random event card", %{game: game} do
      index = 2
      player = Enum.at(game.players, index)
      card = Enum.find(game.cards, fn c -> c.type == :random_event end)
      {updated_game, event} = Monopoly.process_position_change(game, player, card.position)
      assert event.type == :pay or event.type == :receive
      updated_player = Enum.at(updated_game.players, index)
      player_event = Enum.find(updated_player.events, fn e -> e.type == :pay end)

      case event.type do
        :pay ->
          assert player_event == event
          assert length(updated_player.events) == 1
          assert event != nil
          assert event.type == :pay
          assert event.amount >= 0
          assert updated_player.balance == player.balance

        :receive ->
          assert length(updated_player.events) == 0
          event = Enum.find(updated_player.events, fn e -> e.type == :receive end)
          assert event == nil
          assert updated_player.balance != player.balance

        _ ->
          assert false == true
      end
    end
  end

  describe "process player turn" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

      Enum.slice(players_ids, 1, 100)
      |> Enum.each(fn player_id ->
        {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
      end)

      {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
      %{game: game}
    end

    test "should not change player turn because player has events", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      %Player{} = next_player = Enum.at(game.players, 1)
      assert game.player_turn == player_id
      %Monopoly{} = not_updated_game = Monopoly.process_player_turn(game, player_id)
      assert not_updated_game == game
    end

    test "should change player turn because player has no events", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      %Player{} = next_player = Enum.at(game.players, 1)
      assert game.player_turn == player_id
      %Monopoly{} = game = Map.put(game, :players, Enum.map(game.players, fn p ->
        case p.player_id do
          x when x == player_id -> Map.put(p, :events, [])
          _ -> p
        end
      end))
      assert game.round == 1
      updated_game = Monopoly.process_player_turn(game, player_id)
      assert updated_game.player_turn == next_player.player_id
      player = Enum.find(updated_game.players, fn p -> p.player_id == updated_game.player_turn end)
      assert player != nil
      assert player.surrender == false
      assert length(player.events) == 1
      event = List.first(player.events)
      assert event.type == :roll
      assert updated_game.round == 1
    end

    test "should ignore surrendered players", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, 0)
      %Player{player_id: next_player_id} = Enum.at(game.players, 1)
      %Player{} = next_actual_player = Enum.at(game.players, 2)
      assert game.player_turn == player_id
      %Monopoly{} = game = Map.put(game, :players, Enum.map(game.players, fn p ->
        case p.player_id do
          x when x == next_player_id -> Map.put(p, :surrender, true)
          x when x == player_id -> Map.put(p, :events, [])
          _ -> p
        end
      end))
      %Monopoly{} = updated_game = Monopoly.process_player_turn(game, player_id)
      assert updated_game.player_turn == next_actual_player.player_id
      player = Enum.find(updated_game.players, fn p -> p.player_id == updated_game.player_turn end)
      assert player != nil
      assert player.surrender == false
      assert length(player.events) == 1
      event = List.first(player.events)
      assert event.type == :roll
    end

    test "if player is last in array, should set first player as player_turn and change round", %{ game: game } do
      %Player{player_id: player_id} = Enum.at(game.players, length(game.players) - 1)
      game = Map.put(game, :player_turn, player_id)
      %Player{player_id: next_player_id} = Enum.at(game.players, 0)
      assert game.player_turn == player_id
      %Monopoly{} = game = Map.put(game, :players, Enum.map(game.players, fn p ->
        case p.player_id do
          x when x == player_id -> Map.put(p, :events, [])
          _ -> Map.put(p, :events, [])
        end
      end))
      assert game.round == 1
      %Monopoly{} = updated_game = Monopoly.process_player_turn(game, player_id)
      assert updated_game.player_turn == next_player_id
      player = Enum.find(updated_game.players, fn p -> p.player_id == updated_game.player_turn end)
      assert player != nil
      assert player.surrender == false
      assert length(player.events) == 1
      assert updated_game.round == game.round + 1
      event = List.first(player.events)
      assert event.type == :roll
    end
  end

  describe "get new position" do
    setup do
      players_ids = Enum.take_random(1..999_999, 5)
      {:ok, lobby} = Lobby.create(Enum.at(players_ids, 0), [])

      Enum.slice(players_ids, 1, 100)
      |> Enum.each(fn player_id ->
        {:ok, _lobby} = Lobby.join(lobby.lobby_id, player_id)
      end)

      {:ok, %Monopoly{} = game} = Monopoly.start(lobby)
      %{game: game}
    end

    test "should return new position successfully via roll_dice", %{ game: game } do
      {x, y} = Monopoly.roll_dice()
      move_value = x + y
      player = List.first(game.players)
      new_position = Monopoly.get_new_position(game, player.position, move_value)
    end

    test "should return new position successfully ", %{ game: game } do
      expected_position = 15
      move_value = 10
      player = List.first(game.players)
               |> Map.put(:position, expected_position)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      game = Map.put(game, :players, List.replace_at(game.players, player_index, player))
      assert player.position == expected_position
      new_position = Monopoly.get_new_position(game, player.position, move_value)
      assert new_position == move_value + expected_position
    end

    test "should return position < than maximum position", %{ game: game } do
      expected_position = 38
      move_value = 5
      max_position = Enum.max_by(game.cards, fn c -> c.position end) |> Map.fetch!(:position)
      player = List.first(game.players)
               |> Map.put(:position, expected_position)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      game = Map.put(game, :players, List.replace_at(game.players, player_index, player))
      assert player.position == expected_position
      new_position = Monopoly.get_new_position(game, player.position, move_value)
      assert new_position == (move_value + expected_position) - max_position - 1
    end

    test "should return position == maximum position", %{ game: game } do
      expected_position = 37
      move_value = 2
      max_position = Enum.max_by(game.cards, fn c -> c.position end) |> Map.fetch!(:position)
      player = List.first(game.players)
               |> Map.put(:position, expected_position)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      game = Map.put(game, :players, List.replace_at(game.players, player_index, player))
      assert player.position == expected_position
      new_position = Monopoly.get_new_position(game, player.position, move_value)
      assert new_position == move_value + expected_position
    end

    test "should return position == start position", %{ game: game } do
      expected_position = 38
      move_value = 2
      max_position = Enum.max_by(game.cards, fn c -> c.position end) |> Map.fetch!(:position)
      player = List.first(game.players)
               |> Map.put(:position, expected_position)
      player_index = Enum.find_index(game.players, fn p -> p.player_id == player.player_id end)
      game = Map.put(game, :players, List.replace_at(game.players, player_index, player))
      assert player.position == expected_position
      new_position = Monopoly.get_new_position(game, player.position, move_value)
      assert new_position == (move_value + expected_position) - max_position - 1
    end

  end
end
