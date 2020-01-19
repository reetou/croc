defmodule Croc.Accounts.VkUser do
  alias Croc.Accounts
  alias Croc.Repo

  @vk_app_secret_key "mfISGKmHzd94Ncs0C18R"
  @vk_game_secret_key "8hGYUdgW6MzaAJA5zpve"
  @vk_app_id 7262387

  def sign(%{ "vk_app_id" => _vk_app_id, "vk_user_id" => _vk_user_id } = params) do
    excluded_keys =
      params
      |> Map.keys()
      |> Enum.filter(fn k -> String.starts_with?(k, "vk_") == false end)
    params = Map.drop(params, excluded_keys)
    querystring = URI.encode_query(params)
    :crypto.hmac(:sha256, @vk_app_secret_key, querystring)
    |> Base.encode64()
    |> String.replace("=", "")
    |> String.replace("+", "-")
    |> String.replace("/", "_")
    |> String.replace_suffix("=", "")
  end

  def game_sign(%{ "api_id" => app_id, "viewer_id" => vk_id }) do
    :crypto.hash(:md5, app_id <> "_" <> vk_id <> "_" <> "8hGYUdgW6MzaAJA5zpve")
    |> Base.encode16()
    |> String.downcase()
  end
end
