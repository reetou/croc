defmodule CrocWeb.GameController do
  use CrocWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
