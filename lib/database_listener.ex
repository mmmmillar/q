defmodule Q.DatabaseListener do
  require Logger
  use GenServer
  import Ecto.Query, only: [from: 2]

  @channel "new_job"

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def init(_args) do
    seed_data(20000)

    {:ok, _} = load_existing_jobs()

    {:ok, pid} = Postgrex.Notifications.start_link(Q.Repo.config() |> Keyword.merge(pool_size: 1))
    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)

    {:ok, {pid, ref}}
  end

  def handle_info({:notification, _pid, _ref, @channel, payload}, state) do
    {:ok, json} = Poison.decode(payload)

    send_job_to_producer(json["id"])

    {:noreply, state}
  end

  defp load_existing_jobs do
    query =
      from(job in Q.JobRecord,
        where: job.status == "pending",
        select: job.id
      )

    Q.Repo.transaction(fn ->
      Enum.each(Q.Repo.stream(query), &send_job_to_producer/1)
    end)
  end

  defp seed_data(num_records) do
    Stream.chunk_every(1..num_records, 5000)
    |> Stream.each(&seed_batch/1)
    |> Stream.run()
  end

  defp seed_batch(batch) do
    now = NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)

    data =
      Enum.reduce(batch, [], fn _, acc ->
        acc ++
          [
            %{
              inserted_at: now,
              updated_at: now
            }
          ]
      end)

    Q.Repo.insert_all(Q.JobRecord, data)
    Process.sleep(10000)
  end

  defp send_job_to_producer(id), do: GenStage.cast(Q.Producer, {:push_job, id})
end
