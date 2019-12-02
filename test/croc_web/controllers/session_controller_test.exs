defmodule CrocWeb.SessionControllerTest do
  use CrocWeb.ConnCase

  import CrocWeb.AuthTestHelpers

  @create_attrs %{email: "robin@example.com", password: "reallyHard2gue$$"}
  @invalid_attrs %{email: "robin@example.com", password: "cannotGue$$it"}
  @unconfirmed_attrs %{email: "lancelot@example.com", password: "reallyHard2gue$$"}
  @rem_attrs %{email: "robin@example.com", password: "reallyHard2gue$$", remember_me: "true"}
  @no_rem_attrs Map.merge(@rem_attrs, %{remember_me: "false"})

  setup %{conn: conn} do
    add_user("lancelot@example.com")
    user = add_user_confirmed("robin@example.com")
    {:ok, %{conn: conn, user: user}}
  end

  describe "create session" do
    test "login succeeds", %{conn: conn} do
      conn = post(conn, Routes.session_path(conn, :create), session: @create_attrs)
      assert json_response(conn, 200)["access_token"]
    end

    test "login fails for user that is not yet confirmed", %{conn: conn} do
      conn = post(conn, Routes.session_path(conn, :create), session: @unconfirmed_attrs)
      assert json_response(conn, 401)["errors"]["detail"] =~ "need to login"
    end

    test "login fails for user that is already logged in", %{conn: conn, user: user} do
      conn = conn |> add_token_conn(user)
      conn = post(conn, Routes.session_path(conn, :create), session: @create_attrs)
      assert json_response(conn, 401)["errors"]["detail"] =~ "already logged in"
    end

    test "login fails for invalid password", %{conn: conn} do
      conn = post(conn, Routes.session_path(conn, :create), session: @invalid_attrs)
      assert json_response(conn, 401)["errors"]["detail"] =~ "need to login"
    end
  end
end
