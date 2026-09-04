defmodule WordlerWeb.PageController do
  use WordlerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
