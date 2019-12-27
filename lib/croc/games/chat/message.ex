defmodule Croc.Games.Chat.Message do

  @enforce_keys [
    :id,
    :chat_id,
    :text,
    :from,
    :type
  ]

  @derive Jason.Encoder
  defstruct [
    :id,
    :chat_id,
    :text,
    :from,
    :sent_at,
    :to,
    :type
  ]

  def new(chat_id, text, :event = type) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      chat_id: chat_id,
      text: text,
      from: -1,
      to: nil,
      type: type,
      sent_at: DateTime.utc_now() |> DateTime.truncate(:millisecond)
    }
  end

  def new(chat_id, text, from, to, type) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      chat_id: chat_id,
      text: text,
      from: from,
      to: to,
      type: type,
      sent_at: DateTime.utc_now() |> DateTime.truncate(:millisecond)
    }
  end
end
