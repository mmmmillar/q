defmodule Q.Repo do
  use Ecto.Repo,
    otp_app: :q,
    adapter: Ecto.Adapters.Postgres
end

defmodule Q.JobRecord do
  use Ecto.Schema
  require Logger

  @derive {Poison.Encoder, only: [:id, :status, :inserted_at, :updated_at, :retries]}
  schema "jobs" do
    field(:status, :string)
    field(:retries, :integer)
    timestamps()
  end

  def set_started(id) do
    changes = %{status: "in_progress"}

    Q.Repo.transaction(fn ->
      case Q.Repo.get(Q.JobRecord, id) do
        nil ->
          {:error, :not_found}

        record ->
          Q.Repo.update(Ecto.Changeset.change(record, changes))
      end
    end)
  end

  def retry_job(id) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(Q.JobRecord, id) do
        nil ->
          {:error, :not_found}

        record when record.retries >= 3 ->
          Q.Repo.update(Ecto.Changeset.change(record, %{status: "failed"}))
          Q.Stats.increment_failed()

        record ->
          Q.Repo.update(
            Ecto.Changeset.change(record, %{status: "pending", retries: record.retries + 1})
          )
      end
    end)
  end

  def set_completed(id) do
    changes = %{status: "completed"}

    Q.Repo.transaction(fn ->
      case Q.Repo.get(Q.JobRecord, id) do
        nil ->
          {:error, :not_found}

        record ->
          Q.Repo.update(Ecto.Changeset.change(record, changes))
          Q.Stats.increment_completed()
      end
    end)
  end
end
