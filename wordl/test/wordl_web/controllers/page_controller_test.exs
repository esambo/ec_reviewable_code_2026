defmodule WordlWeb.PageControllerTest do
  use WordlWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "WORDL"
  end
end
