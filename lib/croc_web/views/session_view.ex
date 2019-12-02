defmodule CrocWeb.SessionView do
  use CrocWeb, :view

  def render("info.json", %{info: token}) do
    %{access_token: token}
  end
end
