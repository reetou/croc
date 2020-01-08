defmodule CrocWeb.ShopController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.{
    Player,
    Shop
  }
  alias Croc.Accounts.User
  alias Croc.Accounts
  use CrocWeb, :controller
  import CrocWeb.Authorize

  plug :user_check when action not in [:verify_order]

  @group_id 190492517
  @secret Shop.secret()
  @transaction_event_type Shop.vk_transaction_event_type()

  def shop(%{ assigns: %{ current_user: user } } = conn, _params) do
    conn
    |> json(Shop.get_products())
  end

  def verify_order(conn, %{ "type" => "confirmation", "group_id" => @group_id, "secret" => @secret } = params) do
    Logger.warn("Received confirmation")
    IO.inspect(params, label: "Params")
    conn
    |> text(Shop.vk_verify_callback_string())
  end

  def verify_order(conn, %{ "type" => @transaction_event_type, "secret" => @secret, "group_id" => @group_id, "object" => %{ "from_id" => from, "amount" => amount } } = params) do
    IO.inspect(params, label: "Params")
    type = Shop.product_type(amount)
    %User{} = user = Accounts.get_vk_user(from)
    {:ok, products} = Shop.receive_products(user.id, type)
    CrocWeb.Endpoint.broadcast("user:#{from}", "products", %{ products: products, thank_you: true })
    conn
    |> text("ok")
  end

  def verify_order(conn, params) do
    Logger.error("Invalid params at vk callback api #{inspect params}")
    conn
    |> put_status(:bad_request)
    |> json(%{
      errors: %{
        detail: "Invalid params"
      }
    })
  end

  def create_order(conn, %{ "product_type" => type }) when type in ["small_pack", "large_pack"] do
    conn
    |> json(Shop.create_order(String.to_atom(type)))
  end

  def create_order(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      errors: %{
        detail: "Invalid product type"
      }
    })
  end
end
