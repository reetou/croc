defmodule CrocWeb.AdminView do
  use CrocWeb, :view
  alias CrocWeb.AdminView

  def render("401.json", _assigns) do
    %{errors: %{detail: "You need to login to view this resource"}}
  end

  def render("403.json", _assigns) do
    %{errors: %{detail: "You are not authorized to view this resource"}}
  end

  def render("logged_in.json", _assigns) do
    %{errors: %{detail: "You are already logged in"}}
  end

  def render("cards.html", %{ conn: conn, cards: cards }) do
    render_many(cards, AdminView, "card.html", as: :card, conn: conn)
  end
end
