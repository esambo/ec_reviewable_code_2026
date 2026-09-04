defmodule WordlWeb.PageController do
  use WordlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
