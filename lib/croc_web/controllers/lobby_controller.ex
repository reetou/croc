defmodule CrocWeb.LobbyController do
  require Logger
  alias Croc.Games.Monopoly.Lobby
  alias Lobby.Player, as: LobbyPlayer
  alias Croc.Accounts.User
  use CrocWeb, :controller
  import CrocWeb.Authorize

  plug :user_check

  def set_event_cards(%{ assigns: %{ current_user: user } } = conn, %{"lobby_id" => lobby_id, "event_cards_ids" => cards}) do
    with {:ok, lobby, pid} <- Lobby.get(lobby_id),
         true <- LobbyPlayer.in_lobby?(user.id, lobby),
         {:ok, lobby} <- Lobby.set_event_cards(lobby_id, user.id, cards) do
      Logger.debug("Successfully set event cards #{inspect cards}")
      json(conn, %{ lobby: lobby })
    else
      {:error, reason} = r ->
        Logger.error("Received error #{inspect r}")
        conn
        |> put_status(:bad_request)
        |> put_view(CrocWeb.ErrorView)
        |> render("400.json", reason: reason)
    end
  end
end
