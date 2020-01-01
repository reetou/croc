defmodule CrocWeb.UserChannel do
  use Phoenix.Channel
  require Logger

  @prefix "user:"

  def join(@prefix <> user_id = topic, %{ "token" => token }, socket) do
    Logger.warn("Someone is joining to user id #{user_id} in game while his token #{token}")
    with {:ok, token_user_id} <- Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600),
         true <- user_id == "#{token_user_id}" do
      {:ok, %{cool: true, user_id: token_user_id}, assign(socket, :user_id, token_user_id)}
    else
      _ -> {:error, %{ reason: :unauthorized }}
    end
  end

  def join(@prefix <> user_id = topic, _message, socket) do
    Logger.warn("Someone is joining to user id #{user_id} in game while his id in game #{socket.assigns.user_id || "noop"}")
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
