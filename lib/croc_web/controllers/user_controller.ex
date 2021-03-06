defmodule CrocWeb.UserController do
  use CrocWeb, :controller

  import CrocWeb.Authorize

  alias Phauxth.Log
  alias Croc.Accounts
  alias Croc.Accounts.User
  alias Croc.Games.Monopoly.Lobby
  alias Croc.Games.Monopoly
  alias CrocWeb.{Auth.Token, Email}

  action_fallback CrocWeb.FallbackController

  # the following plugs are defined in the controllers/authorize.ex file
  plug :user_check when action in [:index, :show]
  plug :id_check when action in [:edit, :update, :delete]

  def index(conn, _) do
    user = User.get_public_fields(conn.assigns.current_user)
    render(conn, "index.html", lobbies: Lobby.get_all(), user: user, games: Monopoly.get_all())
  end

  def new(conn, _) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => %{"email" => email} = user_params}) do
    key = Token.sign(%{"email" => email})

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        Log.info(%Log{user: user.id, message: "user created"})

        Email.confirm_request(email, Routes.confirm_url(conn, :index, key: key))

        conn
        |> put_flash(
          :info,
          "We have sent you a confirmation email. Please confirm your registration."
        )
        |> redirect(to: Routes.session_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(%Plug.Conn{assigns: %{current_user: _user}} = conn, %{"id" => id}) do
    case Accounts.get_user(id) do
      %User{} = user ->
        render(conn, "show.html", user: user)

      _ ->
        conn
        |> put_view(CrocWeb.ErrorView)
        |> render("404.html")
    end
  end

  def edit(%Plug.Conn{assigns: %{current_user: user}} = conn, _) do
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(%Plug.Conn{assigns: %{current_user: user}} = conn, %{"user" => user_params}) do
    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(%Plug.Conn{assigns: %{current_user: user}} = conn, _) do
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> delete_session(:phauxth_session_id)
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.session_path(conn, :new))
  end
end
