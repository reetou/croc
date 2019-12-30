defmodule Croc.Games.Lobby.Supervisor do
  use DynamicSupervisor
  alias Croc.Games.Monopoly.Lobby
  alias Croc.Games.Chat.Supervisor, as: ChatSupervisor
  require Logger

  def start_link(init_arg) do
    Logger.debug("Started supervisor for lobby")

    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  @impl true
  def init(_init_arg) do
    Logger.debug("Init was ok")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_lobby_process(lobby_id, %{lobby: lobby} = state) do
    name = lobby.lobby_id
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {Lobby, state})
    Logger.debug("Supervisor start child result at create lobby process #{inspect(pid)}")
    Logger.debug("Created lobby process under name #{lobby_id}")
    {:ok, _chat_pid} = ChatSupervisor.create_chat_process(lobby.chat_id, :lobby, lobby.players, lobby_id)
    {:ok, _remover_pid} = schedule_removal(lobby_id)
    {:ok, lobby}
  end

  def stop_lobby_process(lobby_id) do
    {:ok, lobby, pid} = Lobby.get(lobby_id)
    :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
    :ok = ChatSupervisor.stop_chat_process(lobby.chat_id)
    :ok = CrocWeb.Endpoint.broadcast("lobby:all", "lobby_destroy", %{ lobby_id: lobby_id })
  end

  def schedule_removal(lobby_id, after_ms \\ 60000 * 30, reason \\ :lobby_timeout) do
    {:ok, pid} = Task.start(fn ->
      Process.sleep(after_ms)
      with {:ok, lobby, _pid} <- Lobby.get(lobby_id) do
        :ok = CrocWeb.Endpoint.broadcast("lobby:" <> lobby_id, "left", %{
          force: true,
          lobby_id: lobby_id,
          reason: reason
        })
        Enum.each(lobby.players, fn p ->
          Process.sleep(50)
          {:ok, %Lobby{}} = Lobby.leave(lobby_id, p.player_id)
        end)
        Process.sleep(100)
        :ok = stop_lobby_process(lobby_id)
      else
        _ -> Logger.debug("Lobby #{lobby_id} was not removed because already destroyed")
      end
    end)
  end
end
