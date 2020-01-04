defmodule Croc.Games.Monopoly.Shop do
  alias Croc.Repo.Games.Monopoly.{
    EventCard,
    Card
  }
  def get_products() do
    %{
      event_cards: EventCard.get_all()
    }
  end

  def get_merchant_data(amount, order_id) do
    %{
      order_id: order_id,
      amount: amount,
      currency: "RUB",
      ts: DateTime.utc_now() |> DateTime.to_unix()
    }
  end

  def sign(%{ params: params }) do
    Enum.reduce(params, "", fn ({k, v}, acc) ->
      case k do
        :action -> acc
        :data -> acc <> "#{k}=#{Jason.encode!(v)}"
        _ -> acc <> "#{k}=#{v}"
      end
    end)
  end

  def create_order(id, :event_card = type) do
    %EventCard{} = card = EventCard.get_by_id!(id)
    amount = card.price
    merchant_data = get_merchant_data(amount, 123)
    action = "pay-to-group"
    user_id = 536736851
    group_id = 190492517
    order_data = %{
      app_id: 7262387,
      action: action,
      params: %{
        data: %{
          currency: merchant_data.currency,
          product_id: id,
          product_type: type,
          order_id: merchant_data.order_id,
          ts: merchant_data.ts,
          merchant_data: Jason.encode!(merchant_data)
        },
        amount: amount,
        description: "Покупка #{card.name}",
        action: action,
        version: 2,
        group_id: group_id
#        user_id: user_id,
      }
    }
    raw_signature = sign(order_data) <> "mfISGKmHzd94Ncs0C18R"
    signature =
      :crypto.hash(:md5, raw_signature)
      |> Base.encode16()
      |> IO.inspect(label: "Signature is")
    params = Map.put(order_data.params, :sign, signature)
    Map.put(order_data, :params, params)
  end
end
