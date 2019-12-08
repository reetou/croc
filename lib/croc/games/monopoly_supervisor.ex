defmodule Croc.Games.Monopoly.Supervisor do
  use Supervisor
  alias Croc.Games.Monopoly
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

  def create_game_process(game_id, %{ game: game } = state) do
    {:ok, pid} = GenServer.start_link(Monopoly, state)
    Logger.debug("Created game process under name #{game_id}")
    {:ok, game}
  end
end
