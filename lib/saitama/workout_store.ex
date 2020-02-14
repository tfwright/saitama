defmodule Saitama.WorkoutStore do
  use Agent

  def start_link(initial_state) do
    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def add(workout) do
    Agent.update(__MODULE__, fn state ->
      [workout | state]
    end)
  end

  def get(uuid) do
    Agent.get(__MODULE__, fn state ->
      Enum.find(state, fn workout ->
        workout.uuid == uuid
      end)
    end)
  end
end
