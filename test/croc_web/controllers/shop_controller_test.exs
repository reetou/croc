defmodule CrocWeb.ShopControllerTest do

  use CrocWeb.ConnCase
  alias CrocWeb.Auth.Token
  alias Croc.Games.Monopoly.Shop
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
    user = add_vk_user(Enum.random(200_000..200500))
    token = Token.sign(%{ "id" => user.id })
    conn =
      conn
      |> put_req_header("authorization", token)
    {:ok, %{ conn: conn, user: user, token: token }}
  end

  describe "Verify callback url" do
    setup %{ conn: conn } do
      %{ conn: delete_req_header(conn, "authorization") }
    end

    test "should send error if no secret present in request body", %{ conn: conn } do
      body =
        %{
          type: "confirmation",
          group_id: 190492517
        }
        |> Jason.encode!()
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(Routes.shop_path(conn, :verify_order), body)
      assert json_response(conn, 400)["errors"]["detail"] =~ "Invalid params"
    end

    test "should send string on verifying callback api", %{ conn: conn } do
      body =
        %{
          type: "confirmation",
          group_id: 190492517,
          secret: Shop.secret()
        }
        |> Jason.encode!()
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(Routes.shop_path(conn, :verify_order), body)
      assert text_response(conn, 200) == Shop.vk_verify_callback_string()
    end
  end

  describe "Successful verify order: small_pack" do
    setup %{ conn: conn, user: user } do
      body =
        %{
          type: Shop.vk_transaction_event_type(),
          group_id: 190492517,
          secret: Shop.secret(),
          object: %{
            from_id: user.vk_id,
            amount: Shop.small_pack_amount() * 1000,
          }
        }
        |> Jason.encode!()
      %{ conn: delete_req_header(conn, "authorization"), user: user, body: body }
    end

    test "should send ok on successful verifying order", %{ conn: conn, user: user, body: body } do
      assert user.vk_id != nil
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(Routes.shop_path(conn, :verify_order), body)
      assert text_response(conn, 200) == "ok"
    end

    test "should add event cards to user", %{ conn: conn, user: user, body: body } do
      assert user.vk_id != nil
      old_cards = MonopolyUser.get_event_cards(user.id)
      assert is_list(old_cards)
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(Routes.shop_path(conn, :verify_order), body)
      all_event_cards = EventCard.get_all()
      cards = MonopolyUser.get_event_cards(user.id)
      assert length(cards) == length(old_cards) + length(all_event_cards)
    end
  end

  describe "Create shop order" do

    test "should return error if no auth token provided", %{ conn: conn } do
      conn =
        conn
        |> delete_req_header("authorization")
      conn = post(conn, Routes.shop_path(conn, :create_order, product_type: "small_pack"))
      assert json_response(conn, 401)["errors"]["detail"] =~ "need to login"
    end

    test "should return order data", %{ conn: conn } do
      conn = post(conn, Routes.shop_path(conn, :create_order, product_type: "small_pack"))
      response = json_response(conn, 200)
      assert response != nil
      assert response["action"] == "pay-to-group"
      assert response["app_id"] == 7262387
      assert is_binary(response["params"]["sign"])
      assert response["params"]["amount"] > 0
      assert response["params"]["group_id"] == 190492517
    end

    test "should return 404 error", %{ conn: conn } do
      conn = post(conn, Routes.shop_path(conn, :create_order, product_type: "random"))
      assert json_response(conn, 400)["errors"]["detail"] =~ "Invalid product type"
    end
  end
end
