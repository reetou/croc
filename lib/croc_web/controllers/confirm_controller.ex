defmodule CrocWeb.ConfirmController do
  use CrocWeb, :controller

  import CrocWeb.Authorize

  alias Phauxth.Confirm
  alias Croc.Accounts
  alias CrocWeb.Email

  def index(conn, params) do
    case Confirm.verify(params) do
      {:ok, user} ->
        Accounts.confirm_user(user)
        Email.confirm_success(user.email)

        conn
        |> put_view(CrocWeb.ConfirmView)
        |> render("info.json", %{info: "Your account has been confirmed"})

      {:error, _message} ->
        error(conn, :unauthorized, 401)
    end
  end
end
