defmodule Croc.Games.Chat.Admin.Monopoly.Broadcaster do
  alias Croc.Games.Chat.Admin.MessageProducer
  alias CrocWeb.Endpoint
  require Logger

  use GenStage

  def all_game_messages_topic, do: "admin:game_messages"

  def start_link(_opts) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Logger.debug("Init consumer broadcaster")
    {:consumer, :the_state_does_not_matter, subscribe_to: [{MessageProducer, [max_demand: 50, min_demand: 5]}]}
  end

  def handle_events(messages, _from, state) do
    topic = all_game_messages_topic()
    Logger.debug("Broadcasting #{length(messages)} to topic #{topic}")
    Endpoint.broadcast(topic, "messages", %{ messages: messages })
    # We are a consumer, so we would never emit items.
    {:noreply, [], state}
  end
end
