defmodule SaitamaWeb.Live.WorkoutForm do
  use Phoenix.LiveView
  use Phoenix.HTML

  alias SaitamaWeb.Router.Helpers, as: Routes

  alias Saitama.{Workout, Set, Interval}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:workout, Workout.changeset(%Workout{}, %{sets: []}))
      |> assign(:ready, false)

    {:ok, socket}
  end

  def render(assigns) do
    SaitamaWeb.TimerView.render("form.html", assigns)
  end

  def handle_event("save", %{"workout" => params}, socket) do
    {:ok, workout} =
      Workout.changeset(%Workout{}, params)
      |> Ecto.Changeset.apply_action(:insert)

    Saitama.WorkoutStore.add(workout)

    {:noreply,
     live_redirect(socket, to: Routes.live_path(socket, SaitamaWeb.Live.Timer, workout.uuid))}
  end

  def handle_event("validate", %{"workout" => params}, socket) do
    changeset =
      Workout.changeset(%Workout{}, params)
      |> Map.put(:action, :insert)

    {:noreply, assign(socket, workout: changeset)}
  end

  def handle_event("add_set", params, socket) do
    new_workout =
      socket.assigns.workout
      |> Ecto.Changeset.put_embed(
        :sets,
        Ecto.Changeset.get_change(socket.assigns.workout, :sets, []) ++ [build_set]
      )

    {:noreply, assign(socket, :workout, new_workout)}
  end

  def handle_event("add_interval", %{"set-index" => index} = interval, socket) do
    new_sets =
      socket.assigns.workout.changes.sets
      |> Enum.with_index()
      |> Enum.map(fn {set, i} ->
        if i == String.to_integer(index) do
          set
          |> Ecto.Changeset.put_embed(
            :intervals,
            Ecto.Changeset.get_change(set, :intervals, []) ++ [%{}]
          )
        else
          set
        end
      end)

    new_workout =
      socket.assigns.workout
      |> Ecto.Changeset.put_embed(:sets, new_sets)

    {:noreply, assign(socket, :workout, new_workout)}
  end

  def handle_event("reset", _event, socket) do
    socket = assign(socket, :workout, Workout.changeset(%Workout{}, %{sets: []}))

    {:noreply, socket}
  end

  defp build_set do
    %{intervals: []}
  end
end
