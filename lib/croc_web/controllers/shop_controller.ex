defmodule CrocWeb.ShopController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.{
    Player,
    Shop
  }
  alias Croc.Accounts.User
  use CrocWeb, :controller
  import CrocWeb.Authorize

  plug :user_check

  def shop(%{ assigns: %{ current_user: user } } = conn, _params) do
    conn
    |> json(Shop.get_products())
  end

  def create_order(%{ assigns: %{ current_user: user } } = conn, %{ "product_id" => id, "product_type" => "event_card" }) do
    conn
    |> json(Shop.create_order(id, :event_card))
  end
end
