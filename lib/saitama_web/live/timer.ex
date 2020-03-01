defmodule SaitamaWeb.Live.Timer do
  use Phoenix.LiveView

  def render(assigns) do
    SaitamaWeb.TimerView.render("timer.html", assigns)
  end

  def mount(%{"uuid" => uuid}, _session, socket) do
    workout = Saitama.WorkoutStore.get(uuid)

    socket =
      socket
      |> assign(:name, workout.name)
      |> assign(:sets, extract_timer_data(workout.sets))
      |> assign(:current_set_index, 0)
      |> assign(:current_interval_index, 0)
      |> assign(:status, "ready")

    {:ok, socket}
  end

  def handle_event("start", _event, socket) do
    {:ok, timer} = :timer.send_interval(1000, :tick)

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
      |> assign(:current_set_index, 0)
      |> assign(:current_interval_index, 0)

    {:noreply, socket}
  end

  def handle_info(:tick, socket) do
    socket =
      if !intervals_remaining?(socket.assigns.sets) do
        :timer.cancel(socket.assigns.timer)

        assign(socket, :status, "finished")
      else
        current_set_index = socket.assigns.current_set_index
        current_interval_index = socket.assigns.current_interval_index

        set_to_advance =
          socket.assigns.sets
          |> Enum.at(current_set_index)

        interval_to_advance =
          set_to_advance
          |> Map.fetch!("intervals")
          |> Enum.at(current_interval_index)

        {advanced_set, new_set, new_interval} =
          advance(set_to_advance, current_set_index, interval_to_advance, current_interval_index)

        new_sets =
          socket.assigns.sets
          |> List.replace_at(current_set_index, advanced_set)

        socket
        |> assign(:sets, new_sets)
        |> assign(:current_set_index, new_set)
        |> assign(:current_interval_index, new_interval)
      end

    {:noreply, socket}
  end

  defp advance(
         %{"remaining_rest" => rest} = set,
         current_set_index,
         interval,
         current_interval_index
       )
       when rest > 0 do
    set =
      set
      |> Map.update!("remaining_rest", &(&1 - 1))

    {set, current_set_index, current_interval_index}
  end

  defp advance(
         %{"remaining_rest" => 1} = set,
         current_set_index,
         interval,
         current_interval_index
       ) do
    set =
      set
      |> Map.replace!("remaining_rest", 0)

    advance(set, current_set_index, interval, current_interval_index)
  end

  defp advance(
         set,
         current_set_index,
         %{"remaining_duration" => 1} = interval,
         current_interval_index
       ) do
    set =
      set
      |> Map.update!("intervals", fn intervals ->
        intervals
        |> List.update_at(current_interval_index, fn interval ->
          interval |> Map.replace!("remaining_duration", 0)
        end)
      end)
      |> Map.replace!("remaining_rest", Map.fetch!(set, "rest"))

    {set, current_set_index, current_interval_index}
  end

  defp advance(
         set,
         current_set_index,
         %{"remaining_duration" => remaining_duration} = interval,
         current_interval_index
       )
       when remaining_duration > 1 do
    set =
      set
      |> Map.update!("intervals", fn intervals ->
        intervals
        |> List.update_at(current_interval_index, fn interval ->
          interval |> Map.update!("remaining_duration", &(&1 - 1))
        end)
      end)

    {set, current_set_index, current_interval_index}
  end

  defp advance(
         set,
         current_set_index,
         interval,
         current_interval_index
       ) do
    {set, current_set_index, current_interval_index} =
      set
      |> Map.fetch!("intervals")
      |> Enum.find_index(&(Map.fetch!(&1, "remaining_duration") > 0))
      |> case do
        nil ->
          set
          |> Map.fetch!("remaining_reps")
          |> case do
            0 ->
              {set, current_set_index + 1}

            n ->
              set
              |> Map.replace!("remaining_reps", n - 1)
              |> Map.update!("intervals", fn intervals ->
                intervals |> Enum.map(&build_interval/1)
              end)
              |> List.wrap()
              |> List.to_tuple()
              |> Tuple.append(current_set_index)
          end
          |> Tuple.append(0)

        i ->
          {set, current_set_index, i}
      end
  end

  defp extract_timer_data(sets) do
    sets
    |> Enum.map(&build_set/1)
  end

  defp build_set(%{"label" => label, "reps" => reps, "rest" => rest, "intervals" => intervals}) do
    %{
      "label" => label,
      "reps" => reps,
      "rest" => rest,
      "intervals" => intervals |> Enum.map(&build_interval/1),
      "remaining_reps" => reps - 1,
      "remaining_rest" => 0
    }
  end

  defp build_set(struct), do: stringify_keys(struct) |> build_set

  defp build_interval(%{"label" => label, "duration" => duration}) do
    %{
      "label" => label,
      "duration" => duration,
      "remaining_duration" => duration
    }
  end

  defp build_interval(struct), do: stringify_keys(struct) |> build_interval

  defp stringify_keys(struct) do
    struct
    |> Map.from_struct()
    |> Enum.map(fn {k, v} -> {Atom.to_string(k), v} end)
    |> Enum.into(%{})
  end

  defp intervals_remaining?(sets) do
    sets
    |> Enum.any?(fn %{"remaining_reps" => remaining, "intervals" => intervals} ->
      remaining > 0 || Enum.any?(intervals, &(Map.get(&1, "remaining_duration") > 0))
    end)
  end
end
