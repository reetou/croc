defmodule CrocWeb.VkController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Accounts.User
  use CrocWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
