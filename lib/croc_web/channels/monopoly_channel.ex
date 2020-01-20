defmodule CrocWeb.MonopolyChannel do
  use Phoenix.Channel
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Card
  alias Croc.Games.Chat.Message
  alias Croc.Games.Chat
  alias Croc.Games.Chat.Admin.MessageProducer

  use Appsignal.Instrumentation.Decorators
  require Logger

  @prefix "game:monopoly:"

  def join(@prefix <> game_id = topic, %{ "token" => token }, socket) do
    IO.inspect(game_id, label: "Someone is joining")
    with {:ok, user_id} <- Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600),
         {:ok, %Monopoly{} = game, _pid} <- Monopoly.get(game_id) do
      socket =
        socket
        |> assign(:user_id, user_id)
      {:ok, %{ game: game, user_id: user_id }, socket}
    else
      {:error, reason} -> {:error, %{ reason: reason }}
    end
  end

  def join(@prefix <> game_id = topic, _message, socket) do
    IO.inspect(game_id, label: "Someone is joining")
    with {:ok, %Monopoly{} = game, _pid} <- Monopoly.get(game_id) do
      {:ok, %{ game: game }, socket}
    else
      _ -> {:error, %{ reason: :no_game }}
    end
  end

  @decorate channel_action()
  def handle_in("action", %{ "type" => type, "event_id" => event_id }, socket) when type == "roll" do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} game id: #{game_id}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {:roll, socket.assigns.user_id, event_id}) do
      broadcast!(socket, "game_update", %{ game: game })
      {:noreply, socket}
    else
      {:error, _reason} = r -> send_error(socket, r)
    end
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("action", %{ "type" => type, "event_id" => event_id }, socket) when type == "pay" do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} with event_id #{event_id} game id: #{game_id}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {:pay, socket.assigns.user_id, event_id}) do
      broadcast!(socket, "game_update", %{ game: game })
      {:noreply, socket}
    else
      {:error, _reason} = r ->
        Logger.error("Cannot handle pay event #{inspect(r)}")
        send_error(socket, r)
    end
    {:noreply, socket}
  end

  @decorate channel_action()
  def handle_in("action", %{ "type" => type, "event_id" => event_id } = params, socket) when type in ["buy", "reject_buy", "auction_bid", "auction_reject"] do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} in game id: #{game_id}, params #{inspect params}")
    action_type = String.to_atom(type)
    Logger.debug("Gonna send action_type #{action_type}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {action_type, socket.assigns.user_id, event_id}) do
      broadcast!(socket, "game_update", %{ game: game })
      {:noreply, socket}
    else
      {:ok, %{game: game }} -> Logger.error("No event in result")
      {:error, _reason} = r ->
        Logger.error("Cannot handle #{type} event #{inspect(r)}")
        send_error(socket, r)
        {:noreply, socket}
    end
  end

  @decorate channel_action()
  def handle_in("action", %{ "type" => type, "position" => position }, socket) when type in ["put_on_loan", "buyout", "downgrade", "upgrade", "force_auction", "force_teleportation"] do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} in game id: #{game_id}")
    action_type = String.to_atom(type)
    Logger.debug("Gonna send action_type #{action_type}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {action_type, socket.assigns.user_id, position}) do
      broadcast!(socket, "game_update", %{ game: game })
      {:noreply, socket}
    else
      {:error, _reason} = r ->
        Logger.error("Cannot handle #{type} event #{inspect(r)}")
        send_error(socket, r)
        {:noreply, socket}
    end
  end

  @decorate channel_action()
  def handle_in("action", %{ "type" => type }, socket) when type in ["surrender", "force_sell_loan"] do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} in game id: #{game_id}")
    action_type = String.to_atom(type)
    Logger.debug("Gonna send action_type #{action_type}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {action_type, socket.assigns.user_id}) do
      broadcast!(socket, "game_update", %{ game: game })
      {:noreply, socket}
    else
      {:error, _reason} = r ->
        Logger.error("Cannot handle #{type} event #{inspect(r)}")
        send_error(socket, r)
        {:noreply, socket}
    end
  end

  @decorate channel_action()
  def handle_in("action", _params, socket) do
    send_error(socket, {:error, :invalid_action_type})
    {:reply, {:error, %{ reason: :invalid_request_format }}, socket}
  end

  @decorate channel_action()
  def handle_in("chat_message", %{ "chat_id" => chat_id, "text" => text, "to" => to }, socket) when is_binary(text) do
    with true <- String.trim(text) != "",
         {:ok, chat, pid} <- Chat.get(chat_id),
         %Message{} = message <- Message.new(chat_id, text, socket.assigns.user_id, to, :message),
         {:ok, chat, message} <- GenServer.call(pid, {:message, message}) do
      unless message.to != nil do
        broadcast!(socket, "message", message)
        Logger.debug("Broadcasting message! #{inspect message}")
      else
        Logger.debug("Broadcasting personal message #{inspect message}")
        :ok = CrocWeb.Endpoint.broadcast("user:#{socket.assigns.user_id}", "message", message)
        :ok = CrocWeb.Endpoint.broadcast("user:#{message.to}", "message", message)
      end
      Task.start(fn ->
        MessageProducer.sync_message(message)
      end)
      {:noreply, socket}
    else
      {:error, reason} ->
        Logger.error("Error happened at chat message #{inspect reason}")
        send_error(socket, {:error, reason})
        {:noreply, socket}
      false ->
        Logger.debug("Tried to send empty message")
        send_error(socket, {:error, :empty_message})
        {:noreply, socket}
      e ->
        Logger.error("Error happened at chat message with unhandled error #{inspect e}")
        {:noreply, socket}
    end
  end

  @decorate channel_action()
  def handle_in("chat_message", params, socket) do
    Logger.error("Unhandled message with params #{inspect params}")
    {:noreply, socket}
  end

  def send_error(socket, {:error, reason}) do
    push(socket, "error", %{ reason: reason })
  end

  def send_error(socket, %{ reason: _reason } = data) do
    push(socket, "error", data)
  end

  def send_event(%{ game: game, event: event }) do
    topic = @prefix <> game.game_id
    CrocWeb.Endpoint.broadcast(topic, "event", %{ event: event })
    CrocWeb.Endpoint.broadcast(topic, "message", Message.new(game.chat_id, event.text, :event))
  end

  def send_game_end_event(%{ game: game } = payload) do
    CrocWeb.Endpoint.broadcast(@prefix <> game.game_id, "game_end", payload)
  end

  def send_game_update_event(%{ game: game } = payload) do
    CrocWeb.Endpoint.broadcast(@prefix <> game.game_id, "game_update", payload)
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
end
