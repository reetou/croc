defmodule Croc.Games.Chat do
  use GenServer
  require Logger
  alias Croc.Games.Chat.Message

  @registry :chat_registry

  @enforce_keys [
    :id,
    :chat_type,
    :members,
    :messages
  ]

  @derive Jason.Encoder
  defstruct [
    :id,
    :chat_type,
    :members,
    muted_members_ids: [],
    messages: []
  ]

  def new(id, chat_type, members) do
    %__MODULE__{
      id: id,
      chat_type: chat_type,
      members: members,
      muted_members_ids: [],
      messages: []
    }
  end

  def start_link(%__MODULE__{} = state) do
    name = state.id
    {:ok, _pid} = GenServer.start_link(__MODULE__, state, id: name)
  end

  @impl true
  def init(%__MODULE__{} = state) do
    name = state.id
    {:ok, _pid} = Registry.register(@registry, name, state)
    {:ok, state}
  end

  @impl true
  def handle_call({:message, %Message{from: from, type: type} = message}, _from, state) when from != nil or type == :event do
    with :ok <- check_member(state, from),
         :ok <- check_muted(state, from),
         :ok <- validate_message(state, message) do
      state =
        state
        |> Map.put(:messages, state.messages ++ [message])
      update_chat_state(state)
      {:reply, {:ok, state}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get, user_id}, _from, state) do
    filtered_messages = Enum.filter(state.messages, fn %Message{} = m ->
      m.to == nil or m.to == user_id or m.from == user_id
    end)
    # Отправляем только сообщения для всего чата, сообщения от этого пользователя другим
    # и сообщения для этого пользователя от других пользователей
    chat =
      state
      |> Map.put(:messages, filtered_messages)
    {:reply, {:ok, chat}, state}
  end

  @impl true
  def handle_call({:get, :all}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_call({:mute, user_id}, _from, state) do
    muted_members_ids =
      state.muted_members_ids ++ [user_id]
      |> Enum.uniq()
    state =
      state
      |> Map.put(:muted_members_ids, muted_members_ids)
    update_chat_state(state)
    {:reply, {:ok, state}, state}
  end

  def check_muted(%__MODULE__{} = state, user_id) do
    unless Enum.member?(state.muted_members_ids, user_id) != true do
      {:error, :muted}
    else
      :ok
    end
  end

  def validate_message(%__MODULE__{} = state, %Message{} = message) do
     cond do
       message.from == message.to -> {:error, :cannot_send_to_self}
       message.to != nil -> check_member(state, message.to)
       true -> :ok
     end
  end

  def check_member(%__MODULE__{} = state, user_id) do
    member = Enum.find(state.members, fn m -> m.id == user_id end)
    unless member != nil do
      :ok
    else
      {:error, :not_member}
    end
  end

  def get(id) when id != nil do
    Registry.lookup(@registry, id)
    |> case do
         [] ->
           {:error, :no_chat}

         processes ->
           {pid, _init_game} = List.first(processes)

           with {:ok, %__MODULE__{} = chat} <- GenServer.call(pid, {:get, :all}, 5000) do
             {:ok, chat, pid}
           else
             e ->
               e
               |> IO.inspect(label: "Probably a error at get by chat id")
           end
       end
  end

  def update_chat_state(%__MODULE__{} = state) do
    {%__MODULE__{}, %__MODULE__{}} = Registry.update_value(@registry, state.id, fn _ -> state end)
  end

end
