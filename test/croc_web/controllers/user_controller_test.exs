defmodule CrocWeb.UserControllerTest do
  use CrocWeb.ConnCase

  import CrocWeb.AuthTestHelpers

  alias Croc.Accounts

  @create_attrs %{email: "bill@example.com", password: "hard2guess", username: "bill_sadsad"}
  @update_attrs %{email: "william@example.com"}
  @invalid_attrs %{email: nil}

  setup %{conn: conn} do
    conn = conn |> bypass_through(CrocWeb.Router, [:browser]) |> get("/")
    {:ok, %{conn: conn}}
  end

  describe "index" do
    test "lists all entries on index", %{conn: conn} do
      user = add_user("reg@example.com")
      conn = conn |> add_session(user) |> send_resp(:ok, "/")
      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 200) =~ "Hi user"
    end

    test "renders /users error for nil user", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert json_response(conn, 401)["errors"]["detail"] =~ "need to login"
    end
  end

  describe "create user" do
    test "creates user when data is valid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @create_attrs)
      assert redirected_to(conn) == Routes.session_path(conn, :new)
    end

    test "does not create user and renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
      assert html_response(conn, 200) =~ "New user"
    end
  end
end
