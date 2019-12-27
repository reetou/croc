defmodule Croc.Games.Monopoly.Supervisor do
  use DynamicSupervisor
  alias Croc.Games.Monopoly
  alias Croc.Games.Chat
  alias Croc.Games.Chat.Supervisor, as: ChatSupervisor
  require Logger

  def start_link(init_arg) do
    Logger.debug("Started supervisor for monopoly game")

    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  @impl true
  def init(_init_arg) do
    Logger.debug("Init was ok")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_game_process(game_id, %{game: game} = state) do
    name = game_id
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {Monopoly, state})
    Logger.debug("Supervisor start child result at create monopoly game process #{inspect(pid)}")
    Logger.debug("Created monopoly game process under name #{name}")
    {:ok, _chat_pid} = ChatSupervisor.create_chat_process(game.chat_id, :monopoly, game.players)
    {:ok, game}
  end

  def stop_game_process(game_id) do
    {:ok, game, pid} = Monopoly.get(game_id)
    :ok = ChatSupervisor.stop_chat_process(game.chat_id)
    :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end


