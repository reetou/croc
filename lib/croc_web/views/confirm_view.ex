defmodule CrocWeb.ConfirmView do
  use CrocWeb, :view

  def render("info.json", %{info: message}) do
    %{info: %{detail: message}}
  end
end
