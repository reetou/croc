defmodule CrocWeb.VkControllerTest do

  use CrocWeb.ConnCase
  alias CrocWeb.Auth.Token
  alias Croc.{
    Accounts,
    Accounts.User,
    Accounts.MonopolyUser
    }
  alias Croc.Repo.Games.Monopoly.{
    EventCard,
    Card,
    UserEventCard
  }

  import CrocWeb.AuthTestHelpers

  setup %{ conn: conn } do
    params = %{
      "sign" => "89sXLxfVMu7o-hkfM5O3jG1Y8mnPiRgNARzDN3RN3uQ",
      "vk_access_token_settings" => "notify",
      "vk_app_id" => "7262387",
      "vk_are_notifications_enabled" => "0",
      "vk_is_app_user" => "1",
      "vk_is_favorite" => "0",
      "vk_language" => "ru",
      "vk_platform" => "desktop_web",
      "vk_ref" => "other",
      "vk_user_id" => "536736851"
    }
    {:ok, %{ conn: conn, params: params }}
  end

  test "should send error if no sign present", %{ conn: conn, params: params } do
    params = Map.drop(params, ["sign"])
    conn =
      conn
      |> get(Routes.vk_path(conn, :index, params))
    assert text_response(conn, 401) =~ "Sign not found"
  end

  test "should send error if sign is invalid", %{ conn: conn, params: params } do
    params = Map.put(params, "sign", params["sign"] <> "123")
    conn =
      conn
      |> get(Routes.vk_path(conn, :index, params))
    assert text_response(conn, 401) =~ "Invalid sign"
  end

  test "should authenticate successfully", %{ conn: conn, params: params } do
    conn =
      conn
      |> get(Routes.vk_path(conn, :index, params))
    assert html_response(conn, 200) =~ "Croc Vk Mobile"
  end
end
