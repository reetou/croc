defmodule CrocWeb.AdminChannel do
  use Phoenix.Channel
  require Logger
  alias Croc.Accounts
  alias Croc.Accounts.User

  @prefix "admin:"

  def join(@prefix <> "game_messages" = topic, _message, socket) do
#    Logger.warn("Someone is joining to user id #{socket.assigns.user_id} in game")
#    with true <- user_id == "#{socket.assigns.user_id}" do
#      {:ok, %{ cool: true, user_id: user_id }, socket}
#    else
#      _ -> {:error, %{ reason: :unauthorized }}
#    end
    with %User{} = user <- Accounts.get_user(socket.assigns.user_id),
         true <- user.is_admin == true do
      {:ok, socket}
    else
      _ ->
        {:error, %{ reason: :unknown_admin }}
    end
  end

  def handle_in(event, _params, socket) do
    {:noreply, socket}
  end
end
