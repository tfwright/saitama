defmodule SaitamaWeb.Live.Timer do
  require Logger

  use Phoenix.LiveView
  use Phoenix.HTML

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:sets, [])
      |> assign(:status, "pending")
      |> assign(:current_set, 0)
      |> assign(:current_interval, 0)

    {:ok, socket}
  end

  def render(assigns) do
    SaitamaWeb.TimerView.render("index.html", assigns)
  end

  def handle_event("add_set", params, socket) do
    socket =
      assign(
        socket,
        :sets,
        [build_set(params |> Map.put("intervals", [])) | socket.assigns.sets]
        |> Enum.reverse()
      )

    {:noreply, socket}
  end

  def handle_event("add_interval", %{"set_index" => index} = interval, socket) do
    socket =
      assign(
        socket,
        :sets,
        socket.assigns.sets
        |> List.update_at(index |> String.to_integer(), fn set ->
          set
          |> Map.get_and_update(
            "intervals",
            &{&1, [build_interval(interval) | &1] |> Enum.reverse()}
          )
          |> elem(1)
        end)
      )

    {:noreply, socket}
  end

  def handle_event("ready", _event, socket) do
    socket =
      socket
      |> assign(:status, "ready")

    {:noreply, socket}
  end

  def handle_event("clear", _event, socket) do
    socket =
      assign(socket, :sets, [])
      |> assign(:current_set, 0)
      |> assign(:current_interval, 0)
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
    new_sets =
      socket.assigns.sets
      |> Enum.map(&build_set/1)

    socket =
      assign(socket, :sets, new_sets)
      |> assign(:status, "ready")
      |> assign(:current_set, 0)
      |> assign(:current_interval, 0)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    socket =
      if !intervals_remaining?(socket.assigns.sets) do
        Logger.info("finished: #{socket.assigns.sets |> Jason.encode!()}")
        :timer.cancel(socket.assigns.timer)

        assign(socket, :status, "finished")
      else
        current_set = socket.assigns.current_set
        current_interval = socket.assigns.current_interval

        set_to_advance =
          socket.assigns.sets
          |> Enum.at(current_set)
          |> Map.update!("intervals", fn intervals ->
            intervals
            |> List.update_at(current_interval, fn interval ->
              interval |> Map.update!("remaining_duration", &(&1 - 1))
            end)
          end)

        {set_to_advance, new_set, new_interval} =
          set_to_advance
          |> Map.fetch!("intervals")
          |> Enum.find_index(&(Map.get(&1, "remaining_duration") > 0))
          |> case do
            nil ->
              case Map.fetch!(set_to_advance, "remaining_reps") do
                0 ->
                  {set_to_advance, current_set + 1}

                n ->
                  set_to_advance
                  |> Map.replace!("remaining_reps", n - 1)
                  |> Map.update!("intervals", fn intervals ->
                    intervals |> Enum.map(&build_interval/1)
                  end)
                  |> List.wrap()
                  |> List.to_tuple()
                  |> Tuple.append(current_set)
              end
              |> Tuple.append(0)

            i ->
              {set_to_advance, current_set, i}
          end

        new_sets =
          socket.assigns.sets
          |> List.replace_at(current_set, set_to_advance)

        socket
        |> assign(:sets, new_sets)
        |> assign(:current_set, new_set)
        |> assign(:current_interval, new_interval)
      end

    {:noreply, socket}
  end

  defp build_interval(%{"label" => label, "duration" => duration}) do
    %{
      "label" => label,
      "duration" => duration,
      "remaining_duration" => String.to_integer(duration)
    }
  end

  defp build_set(%{"label" => label, "reps" => reps, "intervals" => intervals}) do
    %{
      "label" => label,
      "reps" => reps,
      "intervals" => intervals |> Enum.map(&build_interval/1),
      "remaining_reps" => String.to_integer(reps) - 1
    }
  end

  defp intervals_remaining?(sets) do
    sets
    |> Enum.any?(fn %{"remaining_reps" => remaining, "intervals" => intervals} ->
      remaining > 0 || Enum.any?(intervals, &(Map.get(&1, "remaining_duration") > 0))
    end)
  end
end
