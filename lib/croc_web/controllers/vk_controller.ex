defmodule CrocWeb.VkController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Accounts.User
  alias Croc.Accounts.VkUser
  alias Croc.Accounts
  alias Croc.Sessions
  alias CrocWeb.Auth.Token
  alias Croc.Games.Monopoly.Lobby
  use CrocWeb, :controller

  def index(conn, %{ "auth_key" => auth_key } = params) when is_binary(auth_key) and auth_key != "" do
    user_sign = VkUser.game_sign(params)
    Logger.debug("Checking #{user_sign} vs #{auth_key}")
    with true <- user_sign == auth_key do
      render(conn, "index.html", lobbies: Lobby.get_all(), platform: Map.get(params, "platform", "web"))
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> text("Invalid game sign")
    end
  end

  def index(conn, %{ "sign" => sign } = params) when is_binary(sign) and sign != "" do
    user_sign = VkUser.sign(params)
    with true <- user_sign == sign do
      render(conn, "index.html", lobbies: Lobby.get_all(), platform: Map.get(params, "vk_platform", "desktop_web"))
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> text("Invalid sign")
    end
  end

  def index(conn, params) do
    conn
    |> put_status(:unauthorized)
    |> text("Sign not found")
  end

  def auth(%{ assigns: %{ current_user: user } } = conn, _params) when user != nil do
    Logger.debug("Getting user from token #{user.id}")
    json(conn, %{
      user: User.get_public_fields(user),
      token: conn.assigns.user_token,
      from_token: true
    } |> format_response())
  end

  def auth(conn, %{"id" => vk_id, "first_name" => first_name, "last_name" => last_name, "photo_200" => image_url} = params) do
    params =
      params
      |> Map.put("vk_id", vk_id)
      |> Map.put("image_url", image_url)
    user = Accounts.get_or_create_vk_user(vk_id, params)
    with false <- user.banned == true do
      user_token = Phoenix.Token.sign(conn, "user socket", user.id)
      access_token = CrocWeb.Auth.Token.sign(%{ "id" => user.id })
      conn =
        conn
        |> assign(:access_token, access_token)
        |> assign(:current_user, user)
        |> assign(:user_token, user_token)
        |> json(%{ user: user, token: user_token, access_token: access_token } |> format_response())
    else
      _ ->
        conn
        |> assign(:banned, true)
        |> put_status(:forbidden)
        |> json(%{ error: :banned, ban_id: vk_id })
    end
  end

  def auth(conn, _params) do
    put_status(conn, :forbidden)
    |> put_view(CrocWeb.AuthView)
    |> render("403.json", [])
    |> halt()
  end

  def format_response(params) do
    Map.put(params, :lobbies, Lobby.get_all())
  end
end
