defmodule SaitamaWeb.TimerView do
  use SaitamaWeb, :view

  def control_buttons("stopped") do
    ~E"""
    <button phx-click="start" phx-target="#timer" class="button">start</button>
    <button phx-click="reset" phx-target="#timer" class="button">reset</button>
    """
  end

  def control_buttons("ready") do
    ~E"""
    <button phx-click="start" phx-target="#timer" class="button">start</button>
    """
  end

  def control_buttons("active") do
    ~E"""
    <button phx-click="stop" phx-target="#timer" class="button">stop</button>
    """
  end

  def control_buttons("finished") do
    ~E"""
    <button phx-click="reset" phx-target="#timer" class="button">reset</button>
    """
  end

  def control_buttons(_), do: nil

  def total_duration(sets) when is_list(sets) do
    sets
    |> Enum.map(&total_duration/1)
    |> Enum.sum()
  end

  def total_duration(%{"intervals" => intervals, "reps" => reps, "rest" => rest}) do
    reps *
      Enum.reduce(intervals, 0, fn %{"duration" => d}, sum -> sum + d end) +
      (reps - 1) * rest
  end

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

  def current_remaining_duration(assigns) do
    current_interval(assigns)
    |> Map.get("remaining_duration", 0)
  end

  def current_remaining_rest(assigns) do
    current_set(assigns)
    |> Map.get("remaining_rest")
  end

  def current_interval(%{current_interval_index: current_interval_index} = assigns) do
    current_set(assigns)
    |> Map.get("intervals")
    |> Enum.at(current_interval_index)
  end

  def current_set(%{sets: sets, current_set_index: current_set_index}) do
    Enum.at(sets, current_set_index)
  end
end
