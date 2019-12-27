defmodule CrocWeb.VkController do
  require Logger
  alias Croc.Games.Monopoly
  alias Croc.Accounts.User
  alias Croc.Games.Monopoly.Lobby
  use CrocWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html", lobbies: Lobby.get_all())
  end
end
