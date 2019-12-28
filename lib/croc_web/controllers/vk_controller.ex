defmodule CrocWeb.VkController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Accounts.User
  alias Croc.Accounts
  alias Croc.Sessions
  alias CrocWeb.Auth.Token
  alias Croc.Games.Monopoly.Lobby
  use CrocWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", lobbies: Lobby.get_all())
  end

  def auth(%{ assigns: %{ current_user: user } } = conn, _params) when user != nil do
    Logger.debug("Getting user from token #{user.id}")
    json(conn, %{
      user: User.get_public_fields(user),
      token: conn.assigns.user_token,
      from_token: true
    })
  end

  def auth(conn, %{"id" => vk_id, "first_name" => first_name, "last_name" => last_name, "photo_200" => image_url} = params) do
    params =
      params
      |> Map.put("vk_id", vk_id)
      |> Map.put("image_url", image_url)
    user = Accounts.get_or_create_vk_user(vk_id, params)
    user_token = Phoenix.Token.sign(conn, "user socket", user.id)
    conn =
      conn
      |> assign(:current_user, user)
      |> assign(:user_token, user_token)
      |> json(%{ user: user, token: user_token })
  end

  def auth(conn, _params) do
    put_status(conn, :forbidden)
    |> put_view(CrocWeb.AuthView)
    |> render("403.json", [])
    |> halt()
  end
end
