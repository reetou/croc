defmodule CrocWeb.Authorize do
  @moduledoc """
  Functions to help with authorization.

  See the [Authorization wiki page](https://github.com/riverrun/phauxth/wiki/Authorization)
  for more information and examples about authorization.
  """

  import Plug.Conn
  import Phoenix.Controller

  @doc """
  Plug to only allow authenticated users to access the resource.

  See the user controller for an example.
  """
  def user_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    error(conn, :unauthorized, 401)
  end

  def user_check(conn, _opts), do: conn

  @doc """
  Plug to only allow unauthenticated users to access the resource.

  See the session controller for an example.
  """
  def guest_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts), do: conn

  def guest_check(%Plug.Conn{assigns: %{current_user: _current_user}} = conn, _opts) do
    conn
    |> put_status(:unauthorized)
    |> put_view(CrocWeb.AuthView)
    |> render("logged_in.json", [])
    |> halt()
  end

  def admin_check(%Plug.Conn{assigns: %{current_user: current_user}} = conn, _opts) do
    unless current_user.is_admin == true do
      error(conn, :forbidden, 403)
    else
      IO.inspect(current_user, label: "Allowing to admin")
      conn
    end
  end

  def admin_check(conn, _opts) do
    error(conn, :forbidden, 403)
  end

  @doc """
  Plug to only allow authenticated users with the correct id to access the resource.

  See the user controller for an example.
  """
  def id_check(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    error(conn, :unauthorized, 401)
  end

  def id_check(
        %Plug.Conn{params: %{"id" => id}, assigns: %{current_user: current_user}} = conn,
        _opts
      ) do
    if id == to_string(current_user.id) do
      conn
    else
      error(conn, :forbidden, 403)
    end
  end

  def error(conn, status, code) do
    put_status(conn, status)
    |> put_view(CrocWeb.AuthView)
    |> render("#{code}.json", [])
    |> halt()
  end
end
