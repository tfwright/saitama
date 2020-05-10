defmodule Saitama.Interval do
  use Ecto.Schema
  import Ecto.Changeset
  alias Saitama.Interval

  @derive Jason.Encoder

  @primary_key false
  embedded_schema do
    field(:duration, :integer)
    field(:label, :string)

    field(:remaining_duration, :integer, virtual: true)
  end

  @doc false
  def changeset(%Interval{} = interval, attrs) do
    interval
    |> cast(attrs, [:label, :duration])
    |> validate_required([:label, :duration])
    |> validate_number(:duration, greater_than: 0)
  end
end
