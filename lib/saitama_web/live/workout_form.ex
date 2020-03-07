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
    case Workout.changeset(%Workout{}, params)
         |> Ecto.Changeset.apply_action(:insert) do
      {:ok, workout} ->
        Saitama.WorkoutStore.add(workout)

        {:noreply,
         live_redirect(socket, to: Routes.live_path(socket, SaitamaWeb.Live.Timer, workout.uuid))}

      {:error, changeset} ->
        {:noreply, assign(socket, workout: changeset)}
    end
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
        Ecto.Changeset.get_change(socket.assigns.workout, :sets, []) ++ [%Set{}]
      )

    {:noreply, assign(socket, :workout, new_workout)}
  end

  def handle_event("remove_set", %{"set-index" => index}, socket) do
    new_workout =
      socket.assigns.workout
      |> Ecto.Changeset.put_embed(
        :sets,
        Ecto.Changeset.get_change(socket.assigns.workout, :sets, [])
        |> List.delete_at(String.to_integer(index))
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
            Ecto.Changeset.get_change(set, :intervals, []) ++ [%Interval{}]
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

  def handle_event(
        "remove_interval",
        %{"interval-index" => interval_index, "set-index" => set_index},
        socket
      ) do
    new_sets =
      socket.assigns.workout.changes.sets
      |> Enum.with_index()
      |> Enum.map(fn {set, i} ->
        if i == String.to_integer(set_index) do
          set
          |> Ecto.Changeset.put_embed(
            :intervals,
            Ecto.Changeset.get_change(set, :intervals, [])
            |> List.delete_at(String.to_integer(interval_index))
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
end
