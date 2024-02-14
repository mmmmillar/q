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

  def set_in_progress(id) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record ->
          Ecto.Changeset.change(record, %{status: "in_progress"})
          |> Q.Repo.update()
      end
    end)
  end

  def set_pending(id, retries) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record ->
          Ecto.Changeset.change(record, %{status: "pending", retries: retries})
          |> Q.Repo.update()
      end
    end)
  end

  def set_failed(id) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record ->
          Ecto.Changeset.change(record, %{status: "failed"})
          |> Q.Repo.update()
      end
    end)
  end

  def set_completed(id) do
    Q.Repo.transaction(fn ->
      case Q.Repo.get(__MODULE__, id) do
        nil ->
          {:error, :not_found}

        record ->
          Ecto.Changeset.change(record, %{status: "completed"})
          |> Q.Repo.update()
      end
    end)
  end
end
