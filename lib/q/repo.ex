defmodule Q.Repo do
  use Ecto.Repo,
    otp_app: :q,
    adapter: Ecto.Adapters.Postgres
end

defmodule Q.JobRecord do
  use Ecto.Schema

  @derive {Poison.Encoder, only: [:id, :status, :inserted_at, :updated_at, :retries]}
  schema "jobs" do
    field(:status, :string)
    field(:retries, :integer)
    timestamps()
  end

  def insert_batch(data) do
    Q.Repo.insert_all(__MODULE__, data)
  end

  def set_started(id) do
    changes = %{status: "in_progress"}

    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record ->
          Ecto.Changeset.change(record, changes)
          |> Q.Repo.update()
      end
    end)
  end

  def retry_job(id) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record when record.retries >= 3 ->
          Ecto.Changeset.change(record, %{status: "failed"})
          |> Q.Repo.update()

          Q.Stats.increment_failed()

        record ->
          Ecto.Changeset.change(record, %{status: "pending", retries: record.retries + 1})
          |> Q.Repo.update()
      end
    end)
  end

  def set_completed(id) do
    changes = %{status: "completed"}

    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record ->
          Ecto.Changeset.change(record, changes)
          |> Q.Repo.update()

          Q.Stats.increment_completed()
      end
    end)
  end
end
