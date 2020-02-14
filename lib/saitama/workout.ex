defmodule Saitama.Workout do
  use Ecto.Schema
  import Ecto.Changeset
  alias Saitama.{Workout, Set}

  @primary_key false
  embedded_schema do
    field(:uuid, Ecto.UUID)
    field(:name, :string)

    embeds_many(:sets, Set, on_replace: :delete)
  end

  @doc false
  def changeset(%Workout{} = workout, attrs) do
    workout
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> cast_embed(:sets, required: true, required_message: "must contain at least one item")
    |> put_change(:uuid, Ecto.UUID.generate())
  end
end
