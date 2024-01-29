defmodule Q.Repo do
  use Ecto.Repo,
    otp_app: :q,
    adapter: Ecto.Adapters.Postgres
end

defmodule Q.JobRecord do
  use Ecto.Schema

  @derive {Poison.Encoder, only: [:id, :status, :inserted_at, :updated_at]}
  schema "jobs" do
    field(:status, :string)
    timestamps()
  end

  def update(id, changes \\ %{}) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(Q.JobRecord, id) do
        nil ->
          {:error, :not_found}

        record ->
          changeset = Ecto.Changeset.change(record, changes)
          Q.Repo.update(changeset)
      end
    end)
  end
end
