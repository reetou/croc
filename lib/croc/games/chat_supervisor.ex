defmodule Croc.Games.Chat.Supervisor do
  use DynamicSupervisor
  alias Croc.Games.Chat
  require Logger

  def start_link(init_arg) do
    Logger.debug("Started supervisor for monopoly game")

    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.debug("Chat Supervisor: Init was ok")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_chat_process(id, chat_type, members, entity_id) when is_atom(chat_type) and entity_id != nil do
    state = Chat.new(id, chat_type, members, entity_id)
    {:ok, pid} = DynamicSupervisor.start_child(__MODULE__, {Chat, state})
  end

  def stop_chat_process(id) do
    {:ok, game, pid} = Chat.get(id)
    :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end


