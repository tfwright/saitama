defmodule SaitamaWeb.Live.Timer do
  use Phoenix.LiveView

  def mount(_session, socket) do
    socket =
      socket
      |> assign(:control, "start")
      |> assign(:time_in_secs, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <%= @time_in_secs %>
      <%= if @time_in_secs do %>
        <%= if @time_in_secs > 0 do %>
          <button phx-click=<%= @control %>><%= @control %></button>
        <% end %>
        <%= if @control == "start" do %>
          <button phx-click="reset">reset</button>
        <% end %>
      <% else %>
        <form phx-submit="set_timer">
          <input type="number" name="duration" min="1"></input>
          <input type="submit"/>
        </form>
      <% end %>
    """
  end

  def handle_event("set_timer", %{"duration" => duration}, socket) do
    socket = assign(socket, :time_in_secs, String.to_integer(duration))

    {:noreply, socket}
  end

  def handle_event("start", _event, socket) do
    {:ok, timer} = :timer.send_interval(1000, self(), :tick)

    socket =
      assign(socket, :control, "stop")
      |> assign(:timer, timer)

    {:noreply, socket}
  end

  def handle_event("stop", _event, socket) do
    send(self(), :stop)

    {:noreply, socket}
  end

  def handle_event("reset", _event, socket) do
    send(self(), :stop)

    socket = assign(socket, :time_in_secs, nil)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    time_remaining = socket.assigns.time_in_secs - 1

    if time_remaining == 0 do
      send(self(), :stop)
    end

    {:noreply, assign(socket, time_in_secs: time_remaining)}
  end

  def handle_info(:stop, socket) do
    :timer.cancel(socket.assigns.timer)

    socket = assign(socket, :control, "start")

    {:noreply, socket}
  end
end
