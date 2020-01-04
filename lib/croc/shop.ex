defmodule Croc.Games.Monopoly.Shop do
  alias Croc.Repo.Games.Monopoly.{
    EventCard,
    Card,
    UserEventCard
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

  def get_order_data(amount, description) do
    merchant_data = get_merchant_data(amount, 123)
    action = "pay-to-group"
    user_id = 536736851
    group_id = 190492517
    %{
      app_id: 7262387,
      action: action,
      params: %{
        data: %{
          currency: merchant_data.currency,
          #product_id: id,
          #product_type: type,
          order_id: merchant_data.order_id,
          ts: merchant_data.ts,
          merchant_data: Jason.encode!(merchant_data)
        },
        amount: amount,
        description: "Ваше предложение по игре, если есть",
        action: action,
        version: 2,
        group_id: group_id
        #user_id: user_id,
      }
    }
  end

  def sign(%{ params: params } = order_data) do
    raw_signature = Enum.reduce(params, "", fn ({k, v}, acc) ->
      case k do
        :action -> acc
        :data -> acc <> "#{k}=#{Jason.encode!(v)}"
        _ -> acc <> "#{k}=#{v}"
      end
    end)
    signature = :crypto.hash(:md5, raw_signature <> "mfISGKmHzd94Ncs0C18R")
    |> Base.encode16()
    |> IO.inspect(label: "Signature is")
    params = Map.put(params, :sign, signature)
    Map.put(order_data, :params, params)
  end

  def create_order(:small_pack = type) do
    amount = 15
    order_data = get_order_data(amount, "Напишите Ваше предложение по игре")
    signature = sign(order_data)
  end

  def create_order(:large_pack = type) do
    amount = 100
    order_data = get_order_data(amount, "Напишите Ваше предложение для нового поля или по игре")
    signature = sign(order_data)
  end

  def receive_products(user_id, :no_pack), do: {:ok, []}

  def receive_products(user_id, type) do
    products = EventCard.get_all()
    |> Enum.map(fn c ->
      {:ok, %UserEventCard{}} = UserEventCard.create(%{ monopoly_event_card_id: c.id, user_id: user_id })
    end)
    {:ok, products}
  end
end
