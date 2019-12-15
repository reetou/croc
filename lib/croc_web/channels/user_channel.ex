defmodule CrocWeb.UserChannel do
  use Phoenix.Channel

  def join("user:" <> user_id, _message, socket) do
    IO.inspect(socket, label: "Socket on join user:user_id")
    {:ok, socket}
  end
end
