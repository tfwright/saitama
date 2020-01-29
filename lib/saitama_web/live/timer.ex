defmodule SaitamaWeb.Live.Timer do
  use Phoenix.LiveView
  use Phoenix.HTML

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:intervals, [])
      |> assign(:status, "pending")
      |> assign(:current_interval, 0)

    {:ok, socket}
  end

  def control_buttons("stopped") do
    ~E"""
    <button phx-click="start">start</button>
    <button phx-click="reset">reset</button>
    <button phx-click="clear">clear</button>
    """
  end

  def control_buttons("ready") do
    ~E"""
    <button phx-click="start">start</button>
    <button phx-click="clear">clear</button>
    """
  end

  def control_buttons("active") do
    ~E"""
    <button phx-click="stop">stop</button>
    """
  end

  def control_buttons("finished") do
    ~E"""
    <button phx-click="reset">reset</button>
    <button phx-click="clear">clear</button>
    """
  end

  def control_buttons(_), do: nil

  def format_min_secs(secs) when is_binary(secs),
    do: secs |> String.to_integer() |> format_min_secs

  def format_min_secs(secs) when is_integer(secs) do
    {min, rem_sec} =
      case secs do
        n when n < 60 -> {0, secs}
        _ -> {Integer.floor_div(secs, 60), rem(secs, 60)}
      end

    "#{min}:#{rem_sec |> Integer.to_string() |> String.pad_leading(2, "0")}"
  end

  def render(assigns) do
    ~L"""
      <%= for %{"label" => label, "duration" => duration, "remaining" => remaining} <- @intervals do %>
        <dt><%= label %></dt>
        <dd><%= format_min_secs(duration) %> (<%= format_min_secs(remaining) %>)</dd>
      <% end %>

      <%= control_buttons(@status) %>

      <%= if @status == "pending" || @status == "ready" do %>
        <hr />

        <form phx-submit="add_interval">
          <label>label<label>
          <input type="text" name="label" required />
          <label>duration in seconds<label>
          <input type="number" name="duration" min="1" max="3599" required />
          <input type="submit" value="Add">
        </form>
      <% end %>
    """
  end

  def handle_event("add_interval", event, socket) do
    socket =
      assign(
        socket,
        :intervals,
        [build_interval(event) | socket.assigns.intervals] |> Enum.reverse()
      )
      |> assign(:status, "ready")

    {:noreply, socket}
  end

  def handle_event("clear", _event, socket) do
    socket =
      assign(socket, :intervals, [])
      |> assign(:status, "pending")

    {:noreply, socket}
  end

  def handle_event("start", _event, socket) do
    {:ok, timer} = :timer.send_interval(1000, self(), :tick)

    socket =
      assign(socket, :status, "active")
      |> assign(:timer, timer)

    {:noreply, socket}
  end

  def handle_event("stop", _event, socket) do
    :timer.cancel(socket.assigns.timer)

    {:noreply, assign(socket, :status, "stopped")}
  end

  def handle_event("reset", _event, socket) do
    new_intervals =
      socket.assigns.intervals
      |> Enum.map(&build_interval/1)

    socket =
      assign(socket, :intervals, new_intervals)
      |> assign(:status, "ready")
      |> assign(:current_interval, 0)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    socket =
      if !(socket.assigns.intervals |> Enum.any?(&(&1["remaining"] > 0))) do
        :timer.cancel(socket.assigns.timer)

        assign(socket, :status, "finished")
      else
        current_interval = socket.assigns.current_interval

        new_intervals =
          socket.assigns.intervals
          |> Enum.with_index()
          |> Enum.map(fn {interval, index} ->
            if index == current_interval do
              interval |> Map.update!("remaining", &(&1 - 1))
            else
              interval
            end
          end)

        case new_intervals |> Enum.at(current_interval) do
          %{"remaining" => 0} -> assign(socket, :current_interval, current_interval + 1)
          _ -> socket
        end
        |> assign(:intervals, new_intervals)
      end

    {:noreply, socket}
  end

  defp build_interval(%{"label" => label, "duration" => duration}) do
    %{
      "label" => label,
      "duration" => duration,
      "remaining" => String.to_integer(duration)
    }
  end
end
