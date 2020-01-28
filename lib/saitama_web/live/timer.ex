defmodule SaitamaWeb.Live.Timer do
  use Phoenix.LiveView

  def mount(_session, socket) do
    socket =
      socket
      |> assign(:intervals, [])
      |> assign(:control, "start")
      |> assign(:current_interval, 0)

    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
      <%= for %{"label" => label, "duration" => duration} <- @intervals do %>
        <p><%= label %>: <%= duration %></p>
      <% end %>

      <%= if @intervals |> Enum.any? do %>
        <button phx-click=<%= @control %>><%= @control %></button>
      <% end %>

      <hr />

      <form phx-submit="add_interval">
        <label>label<label>
        <input type="text" name="label" required />
        <label>duration<label>
        <input type="number" name="duration" min="1" required />
        <input type="submit" value="Add">
      </form>
    """
  end

  def handle_event(
        "add_interval",
        %{"label" => _label, "duration" => _duration} = new_interval,
        socket
      ) do
    socket =
      assign(
        socket,
        :intervals,
        [new_interval |> Map.update!("duration", &String.to_integer/1) | socket.assigns.intervals]
        |> Enum.reverse()
      )

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

  def handle_info(:tick, socket) do
    if !(socket.assigns.intervals |> Enum.any?(&(&1["duration"] > 0))) do
      send(self(), :stop)
    end

    current_interval = socket.assigns.current_interval

    new_intervals =
      socket.assigns.intervals
      |> Enum.with_index()
      |> Enum.map(fn {interval, index} ->
        if index == current_interval do
          interval |> Map.update!("duration", &(&1 - 1))
        else
          interval
        end
      end)

    socket =
      case new_intervals |> Enum.at(current_interval) do
        %{"duration" => 0} -> assign(socket, :current_interval, current_interval + 1)
        _ -> socket
      end
      |> assign(:intervals, new_intervals)

    {:noreply, socket}
  end

  def handle_info(:stop, socket) do
    :timer.cancel(socket.assigns.timer)

    socket = assign(socket, :control, "start")

    {:noreply, socket}
  end
end
