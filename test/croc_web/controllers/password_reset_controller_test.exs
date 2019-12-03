defmodule CrocWeb.PasswordResetControllerTest do
  use CrocWeb.ConnCase

  import CrocWeb.AuthTestHelpers

  setup %{conn: conn} do
    user = add_reset_user("gladys@example.com")
    {:ok, %{conn: conn, user: user}}
  end

  describe "create password reset" do
    test "user can create a password reset request", %{conn: conn} do
      valid_attrs = %{email: "gladys@example.com"}
      conn = post(conn, Routes.password_reset_path(conn, :create), password_reset: valid_attrs)
      assert redirected_to(conn, 302) =~ Routes.game_path(conn, :index)
    end

    test "create function fails for no user", %{conn: conn} do
      invalid_attrs = %{email: "prettylady@example.com"}
      conn = post(conn, Routes.password_reset_path(conn, :create), password_reset: invalid_attrs)
      assert redirected_to(conn, 302) =~ Routes.game_path(conn, :index)
    end
  end

  describe "update password reset" do
    test "reset password succeeds for correct key", %{conn: conn} do
      valid_attrs = %{key: gen_key("gladys@example.com"), password: "^hEsdg*F899"}

      reset_conn =
        put(conn, Routes.password_reset_path(conn, :update), password_reset: valid_attrs)

      assert redirected_to(reset_conn, 302) =~ Routes.session_path(reset_conn, :new)

      conn =
        post(conn, Routes.session_path(conn, :create),
          session: %{email: "gladys@example.com", password: "^hEsdg*F899"}
        )

      assert redirected_to(conn, 302) =~ Routes.game_path(conn, :index)
    end

    test "reset password fails for incorrect key", %{conn: conn} do
      invalid_attrs = %{email: "gladys@example.com", password: "^hEsdg*F899", key: "garbage"}
      conn = put(conn, Routes.password_reset_path(conn, :update), password_reset: invalid_attrs)
      assert redirected_to(conn, 302) =~ Routes.password_reset_path(conn, :edit)
    end
  end
end
