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
end
