defmodule Croc.Games.Monopoly.Shop do
  alias Croc.Repo.Games.Monopoly.{
    EventCard,
    Card,
    UserEventCard
  }
  @small_pack_amount 15
  @large_pack_amount 100
  @secret "EFV5gObQbpFe9TUEdZYQMQn3Ed5GmIAjd84H4dVmhUKTk"
  @vk_transaction_event_type "vkpay_transaction"

  def vk_transaction_event_type, do: @vk_transaction_event_type
  def secret, do: @secret
  def small_pack_amount, do: @small_pack_amount
  def large_pack_amount, do: @large_pack_amount

  def vk_verify_callback_string, do: "a1329d3b"

  def get_products() do
    %{
      products: %{
        event_cards: EventCard.get_all()
      },
      small_pack_amount: @small_pack_amount,
      large_pack_amount: @large_pack_amount
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

  def get_order_data(amount, description, type) do
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
          product_type: type,
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
    amount = @small_pack_amount
    order_data = get_order_data(amount, "Напишите Ваше предложение по игре", type)
    signature = sign(order_data)
  end

  def create_order(:large_pack = type) do
    amount = @large_pack_amount
    order_data = get_order_data(amount, "Напишите Ваше предложение для нового поля или по игре", type)
    signature = sign(order_data)
  end

  def receive_products(user_id, :no_pack), do: {:ok, []}

  def receive_products(user_id, type) do
    products = EventCard.get_all()
    |> Enum.map(fn c ->
      {:ok, %UserEventCard{} = user_card} = UserEventCard.create(%{ monopoly_event_card_id: c.id, user_id: user_id })
      user_card
    end)
    {:ok, products}
  end

  def product_type(amount) do
    amount = amount / 1000
    case amount do
      x when x >= @large_pack_amount -> :large_pack
      x when x >= @small_pack_amount -> :small_pack
      x -> :no_pack
    end
  end
end
