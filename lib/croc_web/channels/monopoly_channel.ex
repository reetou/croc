defmodule CrocWeb.MonopolyChannel do
  use Phoenix.Channel
  alias Croc.Games.Monopoly
  alias Croc.Games.Monopoly.Event
  alias Croc.Games.Monopoly.Player
  alias Croc.Games.Monopoly.Card
  require Logger

  @prefix "game:monopoly:"

  def join(@prefix <> game_id, _message, socket) do
    IO.inspect(game_id, label: "Someone is joining")
    with {:ok, %Monopoly{} = game, _pid} <- Monopoly.get(game_id) do
      {:ok, %{ game: game }, socket}
    else
      _ -> {:error, %{ reason: :no_game }}
    end
  end

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

  def handle_in("action", %{ "type" => type, "event_id" => event_id }, socket) when type in ["buy", "reject_buy", "auction_bid", "auction_reject"] do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} in game id: #{game_id}")
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

  def handle_in("action", %{ "type" => type, "position" => position }, socket) when type in ["put_on_loan", "buyout", "downgrade", "upgrade"] do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} in game id: #{game_id}")
    action_type = String.to_atom(type)
    Logger.debug("Gonna send action_type #{action_type}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {action_type, socket.assigns.user_id, position}) do
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

  def handle_in("action", %{ "type" => type }, socket) when type in ["surrender"] do
    @prefix <> game_id = socket.topic
    Logger.debug("Received action type #{type} in game id: #{game_id}")
    action_type = String.to_atom(type)
    Logger.debug("Gonna send action_type #{action_type}")
    with {:ok, %Monopoly{}, pid} <- Monopoly.get(game_id),
         {:ok, %{ game: game }} <- GenServer.call(pid, {action_type, socket.assigns.user_id}) do
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

  def handle_in("action", _params, socket) do
    send_error(socket, {:error, :invalid_action_type})
    {:reply, {:error, %{ reason: :invalid_request_format }}, socket}
  end

  def send_error(socket, {:error, reason}) do
    push(socket, "error", %{ reason: reason })
  end

  def send_error(socket, %{ reason: _reason } = data) do
    push(socket, "error", data)
  end

  def send_event(%{ game: game, event: event }) do
    CrocWeb.Endpoint.broadcast(@prefix <> game.game_id, "event", %{ event: event })
  end

  def send_game_end_event(%{ game: game } = payload) do
    CrocWeb.Endpoint.broadcast(@prefix <> game.game_id, "game_end", payload)
  end
end
