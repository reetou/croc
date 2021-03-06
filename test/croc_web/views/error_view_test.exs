defmodule CrocWeb.ErrorViewTest do
  use CrocWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(CrocWeb.ErrorView, "404.html", []) =~ "HTTP: <span>404</span>"
  end

  test "renders 500.html" do
    assert render_to_string(CrocWeb.ErrorView, "500.html", []) =~ "HTTP: <span>500</span>"
  end
end
