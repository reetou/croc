defmodule Croc.PipelinesTest.Games.Monopoly.CreatePlayerTimeout do

  use ExUnit.Case
  alias Croc.Games.Monopoly.{Event, Player, Lobby, Card}
  alias Croc.Games.Monopoly
  alias Croc.Pipelines.Games.Monopoly.{
    Surrender,
    Events.CreatePlayerTimeout
  }

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Croc.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Croc.Repo, {:shared, self()})
    end
  end

  describe "Player timeout on start" do
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

    test "should have timeout pid and turn_timeout_at", %{ game: game } do
      assert game.on_timeout == :surrender
      assert game.turn_timeout_at != nil
    end

    test "should overwrite timeout pid and kill old process on new timeout", %{ game: game } do
      old_turn_timeout_at = game.turn_timeout_at
      Process.sleep(1000)
      {:ok, args} = CreatePlayerTimeout.call(%{
        game: game,
        on_timeout: :surrender
      })
      game = args.game
      assert game.turn_timeout_at != old_turn_timeout_at
    end

    test "should surrender with callback :surrender", %{ game: game } do
      old_turn_timeout_at = game.turn_timeout_at
      Process.sleep(1000)
      {:ok, args} = CreatePlayerTimeout.call(%{
        game: game,
        on_timeout: :surrender
      })
      game = args.game
      assert game.turn_timeout_at != old_turn_timeout_at
    end
  end

end
