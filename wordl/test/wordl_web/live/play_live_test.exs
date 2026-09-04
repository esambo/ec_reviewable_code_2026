defmodule WordlWeb.PlayLiveTest do
  use WordlWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Wordl.Dictionary
  alias Wordl.Games

  test "colors submitted guesses on the board", %{conn: conn} do
    {:ok, puzzle} = Games.generate_puzzle()
    {:ok, play} = Games.start_play(puzzle, "Ada")
    miss = Enum.find(Dictionary.secrets(), &(&1 != puzzle.secret))

    {:ok, view, _html} = live(conn, ~p"/play/#{play.id}")

    html =
      view
      |> form("form", guess: %{word: miss})
      |> render_submit()

    assert html =~ String.upcase(String.first(miss))
    assert html =~ "bg-green-600" or html =~ "bg-yellow-500" or html =~ "bg-zinc-500"
  end

  test "typing a draft guess does not crash the board", %{conn: conn} do
    {:ok, puzzle} = Games.generate_puzzle()
    {:ok, play} = Games.start_play(puzzle, "Ada")
    {:ok, view, _html} = live(conn, ~p"/play/#{play.id}")

    html =
      view
      |> form("#guess-form", guess: %{word: "hello"})
      |> render_change()

    assert html =~ "H"
    assert html =~ "E"
  end
end
