defmodule CrocWeb.Router do
  use CrocWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug
  use ExAdmin.Router
  import CrocWeb.Authorize

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Phauxth.Authenticate
    plug Phauxth.Remember, create_session_func: &CrocWeb.Auth.Utils.create_session/1
    plug :put_user_token
  end

  pipeline :vk do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_frame_settings
    plug :put_layout, {CrocWeb.VkMobileView, "layout.html"}
  end

  pipeline :admin do
    plug :admin_check
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
    plug Phauxth.AuthenticateToken
    plug :put_user_token
  end

  scope "/", CrocWeb do
    pipe_through :browser

    get "/", GameController, :index
    get "/game/:game_id", GameController, :game

    get "/confirms", ConfirmController, :index
    resources "/password_resets", PasswordResetController, only: [:new, :create]
    get "/password_resets/edit", PasswordResetController, :edit
    put "/password_resets/update", PasswordResetController, :update
    get "/login", SessionController, :new
    get "/register", UserController, :new
    get "/profile", UserController, :index
  end

  scope "/admin", CrocWeb do
    pipe_through :browser
    pipe_through :admin
    get "/", AdminController, :index
    get "/games/messages", AdminController, :all_games_messages
  end

  # setup the ExAdmin routes on /admin
  scope "/exadmin", ExAdmin do
    pipe_through :browser
    pipe_through :admin
    admin_routes()
  end

  scope "/api", CrocWeb do
    pipe_through :api
    post "/auth/vk", VkController, :auth
    resources "/users", UserController, except: [:new, :index]
    resources "/sessions", SessionController, only: [:create, :delete]
    post "/lobby/set-event-cards", LobbyController, :set_event_cards
    get "/shop", ShopController, :shop
    post "/shop/orders/create", ShopController, :create_order
    post "/shop/orders/verify", ShopController, :verify_order
  end

  scope "/vk", CrocWeb do
    pipe_through :vk
    get "/", VkController, :index
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  defp put_user_token(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

  defp put_frame_settings(conn, _) do
    conn
    |> put_resp_header("x-frame-ancestors", "'self' https://vk.com")
    |> put_resp_header("x-frame-options", "ALLOW-FROM https://vk.com")
  end
end
