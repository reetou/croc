defmodule Croc.Games.Chat.Admin.MessageProducer do
  require Logger
  use GenStage

  @default_state %{
    messages: []
  }

  def start_link(_) do
    GenStage.start_link(__MODULE__, @default_state, name: __MODULE__)
  end

  def init(_) do
    Logger.debug("Init message producer")
    {:producer, @default_state}
  end

  def sync_message(message, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:message, message}, timeout)
  end

  def handle_call({:message, message}, _from, state) do
    {:reply, :ok, [message], %{state | messages: state.messages ++ [message]}}
  end

  def handle_demand(demand, state) do
    Logger.debug("Consumer asking for demand #{demand}")
    # We check if we're able to satisfy the demand and fetch
    # events if we aren't.
    events =
      if length(state.messages) >= demand do
        state.messages
      else
        []
      end

    # We dispatch only the requested number of events.
    {to_dispatch, remaining} = Enum.split(events, demand)

    {:noreply, to_dispatch, %{state | messages: remaining}}
  end
end
