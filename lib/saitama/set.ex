defmodule Saitama.Set do
  use Ecto.Schema
  import Ecto.Changeset
  alias Saitama.{Set, Interval}

  @derive Jason.Encoder

  @primary_key false
  embedded_schema do
    field(:label, :string)
    field(:reps, :integer, default: 1)
    field(:rest, :integer, default: 0)

    field(:remaining_reps, :integer, virtual: true)
    field(:remaining_rest, :integer, virtual: true)

    embeds_many(:intervals, Interval, on_replace: :delete)
  end

  @doc false
  def changeset(%Set{} = set, attrs) do
    set
    |> cast(attrs, [:label, :reps, :rest])
    |> validate_required([:label])
    |> validate_number(:reps, greater_than_or_equal_to: 1)
    |> validate_number(:rest, greater_than_or_equal_to: 0)
    |> cast_embed(:intervals, required: true, required_message: "must contain at least one item")
  end
end
