defmodule Croc.Games.Lobby.Supervisor do
  use Supervisor
  alias Croc.Games.Monopoly.Lobby
  require Logger

  def start_link do
    Logger.debug("Started supervisor for lobby")
    children = []
    options = [
      strategy: :one_for_one,
      name: __MODULE__
    ]
    Supervisor.start_link(children, options)
  end

  def create_lobby_process(lobby_id, %{ lobby: lobby } = state) do
    {:ok, pid} = GenServer.start_link(Lobby, state)
    Logger.debug("Created lobby process under name #{lobby_id}")
    {:ok, lobby}
  end

  def stop_lobby_process(lobby_id) do
    {:ok, lobby, pid} = Lobby.get(lobby_id)
    GenServer.stop(pid)
  end
end
