defmodule CrocWeb.Router do
  use CrocWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Phauxth.Authenticate
    plug Phauxth.Remember, create_session_func: &CrocWeb.Auth.Utils.create_session/1
  end

  pipeline :authorized do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Phauxth.Authenticate
    plug Phauxth.Remember, create_session_func: &CrocWeb.Auth.Utils.create_session/1
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_flash
    plug Phauxth.AuthenticateToken
  end

  scope "/", CrocWeb do
    pipe_through :browser

    get "/", GameController, :index

    get "/confirms", ConfirmController, :index
    resources "/password_resets", PasswordResetController, only: [:new, :create]
    get "/password_resets/edit", PasswordResetController, :edit
    put "/password_resets/update", PasswordResetController, :update
    get "/login", SessionController, :new
    get "/register", UserController, :new
    get "/profile", UserController, :index
  end

  scope "/api", CrocWeb do
    pipe_through :api
    resources "/users", UserController, except: [:new, :index]
    resources "/sessions", SessionController, only: [:create, :delete]
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end
end
