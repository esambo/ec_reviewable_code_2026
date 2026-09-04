defmodule WordlWeb.HomeLiveTest do
  use WordlWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Wordl.Games

  test "generates a secret and starts a named game", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "WORDL"
    assert html =~ "No secret yet"

    html =
      view
      |> element("button", "Generate new secret word")
      |> render_click()

    assert html =~ "A five-letter secret is live"

    result =
      view
      |> form("form", player: %{name: "Ada"})
      |> render_submit()

    {:ok, play_view, play_html} = follow_redirect(result, conn)
    assert play_html =~ "Playing as"
    assert play_html =~ "Ada"
    assert render(play_view) =~ "tries left"
  end

  test "shows finished and active players for the current word", %{conn: conn} do
    {:ok, puzzle} = Games.generate_puzzle()
    {:ok, ada} = Games.start_play(puzzle, "Ada")
    {:ok, _} = Games.submit_guess(ada, puzzle.secret)
    {:ok, _} = Games.start_play(puzzle, "Grace")

    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Ada"
    assert html =~ "1 tries"
    assert html =~ "Grace"
    assert html =~ "0 suggestion"
  end
end
