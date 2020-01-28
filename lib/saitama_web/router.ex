defmodule SaitamaWeb.Router do
  use SaitamaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SaitamaWeb do
    pipe_through :browser

    get "/", PageController, :index

    live "/timer", Live.Timer
  end

  # Other scopes may use custom stacks.
  # scope "/api", SaitamaWeb do
  #   pipe_through :api
  # end
end