defmodule CrocWeb.AdminController do
  use CrocWeb, :controller

  import CrocWeb.Authorize

  alias CrocWeb.AdminView
  alias Phauxth.Log
  alias Croc.Accounts
  alias Croc.Accounts.User
  alias Croc.Games.Chat.Admin.Monopoly.Broadcaster
  alias Croc.Games.Monopoly.{
    Lobby,
  }
  alias Croc.Repo.Games.Monopoly.Card
  alias Croc.Games.Monopoly
  alias CrocWeb.{Auth.Token, Email}

  action_fallback CrocWeb.FallbackController

  # the following plugs are defined in the controllers/authorize.ex file
  plug :user_check
  plug :admin_check

  def index(conn, _) do
    render(conn, "index.html", lobbies: Lobby.get_all(), games: Monopoly.get_all())
  end

  def cards(conn, _) do
    render(conn, "cards.html", cards: Card.get_all())
  end

  def show_card(conn, %{ "id" => id } = params) do
    IO.inspect(params, label: "Params at show card")
    card = Card.get_by_id(id)
    render(conn, :card_form,
      changeset: Card.changeset(card, %{}),
      types: Card.types(),
      monopoly_types: Card.monopoly_types()
    )
  end

  def edit_card(conn, %{ "id" => id, "card" => %{ "upgrade_level_multipliers" => [""] } = card } = params) do
    card =
      card
      |> Map.put("upgrade_level_multipliers", nil)
      |> Map.put("max_upgrade_level", 0)
    edit_card(conn, %{ "id" => id, "card" => card })
  end

  def edit_card(conn, %{ "id" => id, "card" => %{ "upgrade_level_multipliers" => upgrade_level_multipliers } = card } = params) do
    %Card{} = Card.update!(Card.get_by_id(id), card)
    conn
    |> put_flash(:info, "Updated successfully")
    |> redirect(to: Routes.admin_path(conn, :show_card, id))
  end

  def edit_card(conn, %{ "id" => id, "card" => card } = params) do
    card =
      card
      |> Map.put("upgrade_level_multipliers", nil)
      |> Map.put("max_upgrade_level", 0)
    edit_card(conn, %{ "id" => id, "card" => card })
  end

  def all_games_messages(conn, _params) do
    conn
    |> render(:game_messages, topic: Broadcaster.all_game_messages_topic())
  end
end
