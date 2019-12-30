defmodule CrocWeb.UserChannel do
  use Phoenix.Channel
  require Logger

  @prefix "user:"

  def join(@prefix <> user_id = topic, _message, socket) do
    Logger.warn("Someone is joining to user id #{user_id} in game")
    with true <- user_id == "#{socket.assigns.user_id}" do
      {:ok, %{ cool: true, user_id: user_id }, socket}
    else
      _ -> {:error, %{ reason: :unauthorized }}
    end
  end

  def handle_in(_action, _params, socket) do
    {:noreply, socket}
  end
end
