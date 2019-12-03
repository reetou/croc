defmodule CrocWeb.ConfirmControllerTest do
  use CrocWeb.ConnCase

  import CrocWeb.AuthTestHelpers

  setup %{conn: conn} do
    add_user("arthur@example.com")
    {:ok, %{conn: conn}}
  end

  test "confirmation succeeds for correct key", %{conn: conn} do
    conn = get(conn, Routes.confirm_path(conn, :index, key: gen_key("arthur@example.com")))
    assert redirected_to(conn, 302) =~ Routes.session_path(conn, :new)
  end

  test "confirmation fails for incorrect key", %{conn: conn} do
    conn = get(conn, Routes.confirm_path(conn, :index, key: "garbage"))
    assert redirected_to(conn, 302) =~ Routes.session_path(conn, :new)
  end

  test "confirmation fails for incorrect email", %{conn: conn} do
    conn = get(conn, Routes.confirm_path(conn, :index, key: gen_key("gerald@example.com")))
    assert redirected_to(conn, 302) =~ Routes.session_path(conn, :new)
  end
end
