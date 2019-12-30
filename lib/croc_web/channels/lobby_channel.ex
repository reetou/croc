defmodule CrocWeb.LobbyChannel do
  use Phoenix.Channel
  require Logger
  alias Croc.Games.Lobby.Supervisor
  alias Croc.Games.Monopoly.Lobby
  alias Croc.Games.Monopoly.Lobby.Player, as: LobbyPlayer
  alias Croc.Games.Monopoly
  use Appsignal.Instrumentation.Decorators

  def join("lobby:all", %{ "token" => token }, socket) when token != nil do
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
      {:ok, user_id} ->
        with {:ok, %LobbyPlayer{lobby_id: lobby_id}} <- LobbyPlayer.get_current_lobby_data(user_id) do
          Logger.debug("Has current lobby data, gonna send it")
          topic = "lobby:" <> lobby_id
          updated_socket =
            socket
            |> assign(:user_id, user_id)
            |> assign(:topics, [])
            |> put_new_topics([topic])
          {:ok, %{lobby_id: lobby_id, user_id: user_id}, updated_socket}
        else
          _ ->
            updated_socket = assign(socket, :user_id, user_id)
            {:ok, %{lobby_id: nil, user_id: user_id}, updated_socket}
        end
      {:error, reason} ->
        {:ok, %{lobby_id: nil, user_id: nil, error: reason}, socket}
    end
  end

  def join("lobby:all", _message, socket) do
    with {:ok, %LobbyPlayer{lobby_id: lobby_id}} <- LobbyPlayer.get_current_lobby_data(socket.assigns.user_id) do
      Logger.debug("Has current lobby data, gonna send it")
      topic = "lobby:" <> lobby_id
      updated_socket = socket
                       |> assign(:topics, [])
                       |> put_new_topics([topic])
      {:ok, %{lobby_id: lobby_id, user_id: socket.assigns.user_id}, updated_socket}
    else
      _ ->
        Logger.debug("No current lobby data found for user")
        {:ok, %{lobby_id: nil, user_id: socket.assigns.user_id}, socket}
    end
  end

  def join("lobby:" <> lobby_id, %{ "token" => token }, socket) do
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600),
         {:ok, %Lobby{} = lobby, _pid} <- Lobby.get(lobby_id),
         true <- LobbyPlayer.in_lobby?(user_id, lobby) do
      Logger.debug("Joined to personal lobby #{lobby_id}")
      {:ok, socket}
    else
      {:error, reason} ->
        Logger.error("Throwing error: #{reason}")
        {:error, %{ reason: reason }}
      e ->
        Logger.error("Unknown error when joining with token #{inspect e}")
        {:error, %{reason: :unknown_error}}
    end
  end

  def join("lobby:" <> lobby_id, _message, socket) do
    with {:ok, %Lobby{} = lobby, _pid} <- Lobby.get(lobby_id),
         true <- LobbyPlayer.in_lobby?(socket.assigns.user_id, lobby) do
      Logger.debug("Joined to personal lobby #{lobby_id}")
      {:ok, socket}
    else
      e ->
        Logger.error("Probably not in lobby")
        {:error, %{reason: :not_in_lobby}}
    end
  end

  @decorate channel_action()
  def handle_in(action, _params, %{ assigns: %{ user_id: nil } } = socket) when action in ["create", "join", "leave", "start"] do
    send_error(socket, {:error, :authenticate_first})
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("create", %{"options" => options} = params, socket) do
    case Lobby.create(socket.assigns.user_id, options) do
      {:ok, %Lobby{} = lobby} ->
        Logger.debug("Created successfully")
        topic = "lobby:" <> lobby.lobby_id
        topics = [topic]
        Logger.debug("Adding user to topic #{topic}")
        updated_socket = socket
                         |> assign(:topics, [])
                         |> put_new_topics(topics)
        broadcast(updated_socket, "new_lobby", lobby)
        notify_joined(updated_socket, lobby.lobby_id)
      {:error, reason} = e ->
        IO.inspect(e, label: "Error")
        send_error(socket, %{ reason: reason })
      e ->
        IO.inspect(e, label: "Error")
        send_error(socket, %{ reason: :unknown_error })
    end
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("leave", %{"lobby_id" => lobby_id}, socket) do
    with {:ok, %Lobby{} = lobby} <- Lobby.leave(lobby_id, socket.assigns.user_id) do
      topic = "lobby:" <> lobby_id
      Logger.debug("Unsubscribing from topic #{topic}")
      :ok = CrocWeb.Endpoint.unsubscribe(topic)
      push(socket, "left", %{ lobby_id: lobby_id })
      unless length(lobby.players) == 0 do
        Logger.debug("Left successfully")
      else
        Logger.debug("Destroying lobby because no players in it")
        Supervisor.stop_lobby_process(lobby_id)
      end
    else
      e ->
        send_error(socket, e)
    end
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("start", %{"lobby_id" => lobby_id}, socket) do
    with {:ok, %Lobby{} = lobby, _pid} <- Lobby.get(lobby_id),
         true <- LobbyPlayer.in_lobby?(socket.assigns.user_id, lobby),
         {:ok, %Monopoly{} = game} <- Monopoly.start(lobby) do
      Logger.debug("Starting game from lobby #{lobby_id} for user #{socket.assigns.user_id}")
    else
      e ->
        send_error(socket, e)
    end
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("join", %{"lobby_id" => lobby_id}, socket) do
    with {:ok, %Lobby{} = lobby} <- Lobby.join(lobby_id, socket.assigns.user_id) do
      Logger.debug("Joined successfully")
      topics = ["lobby:" <> lobby.lobby_id]
      Logger.debug("Putting topics")
      updated_socket = socket
                       |> assign(:topics, [])
                       |> put_new_topics(topics)
      notify_joined(updated_socket, lobby.lobby_id)
      {:noreply, updated_socket}
    else
      e ->
        send_error(socket, e)
        {:noreply, socket}
    end
  end

  @decorate channel_action()
  def handle_in("kick", %{user_id: user_id}, socket) do
    broadcast!(socket, "kick", %{user_id: user_id})
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in(action, params, socket) do
    {:noreply, socket}
  end

  def send_error(socket, {:error, reason}) do
    push(socket, "error", %{ reason: reason })
  end

  def send_error(socket, data) do
    push(socket, "error", data)
  end

  defp put_new_topics(socket, topics) do
    Enum.reduce(topics, socket, fn topic, acc ->
      topics = acc.assigns.topics
      if topic in topics do
        acc
        Logger.debug("Ignoring topic #{topic} because already subscribed")
      else
        :ok = CrocWeb.Endpoint.subscribe(topic)
        assign(acc, :topics, [topic | topics])
      end
    end)
  end

  def create_reply(topic, payload) do
    %{
      topic: topic,
      status: :ok,
      payload: payload
    }
  end
  def notify_joined(socket, lobby_id) do
    push(socket, "joined", %{ lobby_id: lobby_id })
  end

  def create_error_reply({:error, reason}) do
    %{
      topic: "error",
      status: :ok,
      payload: %{
        reason: reason
      }
    }
  end

  def create_error_reply(payload) do
    %{
      topic: "error",
      status: :ok,
      payload: payload
    }
  end

  def handle_info(msg, socket) do
    {:noreply, socket}
  end
end
