defmodule CrocWeb.GameController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.Player
  alias Croc.Accounts.User
  use CrocWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def game(%{ assigns: %{ current_user: nil } } = conn, %{"game_id" => game_id} = params) do
    with {:ok, _info} <- UUID.info(game_id),
         {:ok, game, pid} <- Monopoly.get(game_id) do
      Logger.debug("Will search for game_id #{game_id}")
      render(conn, "game.html", game: game, is_player: false, user: nil)
    else
      _ ->
        conn
        |> put_flash(:error, "Game not found")
        |> redirect(to: Routes.game_path(conn, :index))
    end
  end

  def game(%{ assigns: %{ current_user: %User{ id: user_id } } } = conn, %{"game_id" => game_id} = params) do
    with {:ok, _info} <- UUID.info(game_id),
         {:ok, game, pid} <- Monopoly.get(game_id),
         is_player when is_boolean(is_player) <- Player.is_playing?(%{game: game, player_id: user_id}) do
      Logger.debug("Will search for game_id #{game_id}")
      render(conn, "game.html", game: game, is_player: is_player, user: User.get_public_fields(conn.assigns.current_user))
    else
      _ ->
        conn
        |> put_flash(:error, "Game not found")
        |> redirect(to: Routes.game_path(conn, :index))
    end
  end
end
