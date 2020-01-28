defmodule SaitamaWeb.PageController do
  use SaitamaWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
