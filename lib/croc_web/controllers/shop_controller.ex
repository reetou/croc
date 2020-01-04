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

  def shop(%{ assigns: %{ current_user: user } } = conn, _params) do
    conn
    |> json(Shop.get_products())
  end

  def verify_order(conn, %{ "type" => "confirmation", "group_id" => @group_id } = params) do
    Logger.warn("Received confirmation")
    IO.inspect(params, label: "Params")
    string = "a1329d3b"
    conn
    |> text(string)
  end

  def verify_order(conn, %{ "type" => "vkpay_transaction", "group_id" => @group_id, "object" => %{ "from_id" => from, "amount" => amount } } = params) do
    IO.inspect(params, label: "Params")
    amount = amount / 1000
    type =
      case amount do
        x when x >= 100 -> :large_pack
        x when x >= 15 -> :small_pack
        x ->
          IO.inspect(x, label: "Giving no pack because amount is")
          :no_pack
      end
    %User{} = user = Accounts.get_vk_user(from)
    {:ok, products} = Shop.receive_products(user.id, type)
    |> IO.inspect(label: "Giving products")
    CrocWeb.Endpoint.broadcast("user:#{from}", "products", %{ products: products, thank_you: true })
    conn
    |> text("ok")
  end

  def create_order(conn, %{ "product_type" => type }) when type in ["small_pack", "large_pack"] do
    conn
    |> json(Shop.create_order(String.to_atom(type)))
  end
end
