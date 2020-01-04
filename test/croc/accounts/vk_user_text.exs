defmodule Croc.AccountsTest.VkUserTest do
  use Croc.DataCase

  alias Croc.Accounts
  alias Croc.Accounts.VkUser

  setup do
    params = %{
      "sign" => "89sXLxfVMu7o-hkfM5O3jG1Y8mnPiRgNARzDN3RN3uQ",
      "vk_access_token_settings" => "notify",
      "vk_app_id" => "7262387",
      "vk_are_notifications_enabled" => "0",
      "vk_is_app_user" => "1",
      "vk_is_favorite" => "0",
      "vk_language" => "ru",
      "vk_platform" => "desktop_web",
      "vk_ref" => "other",
      "vk_user_id" => "536736851"
    }
    %{params: params}
  end

  test "should sign successfully", %{ params: params } do
    expected = "89sXLxfVMu7o-hkfM5O3jG1Y8mnPiRgNARzDN3RN3uQ"
    VkUser.sign(params) == expected
  end

  test "should sign successfully with useless params too", %{ params: params } do
    params =
      params
      |> Map.put("something", "useless")
      |> Map.put("something1", "useless2")
      |> Map.put("really_useless", true)
      |> Map.put("sadasdsadasdsadsadsadssadsad13211SC_", true)
    expected = "89sXLxfVMu7o-hkfM5O3jG1Y8mnPiRgNARzDN3RN3uQ"
    VkUser.sign(params) == expected
  end
end
