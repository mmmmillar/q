defmodule Q.DatabaseListener do
  require Logger
  use GenServer

  @channel "new_job"

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, [init_args], name: __MODULE__)
  end

  def init(_args) do
    {:ok, pid} = Postgrex.Notifications.start_link(Q.Repo.config() |> Keyword.merge(pool_size: 1))
    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)

    {:ok, {pid, ref}}
  end

  def handle_info({:notification, _pid, _ref, @channel, payload}, state) do
    {:ok, json} = Poison.decode(payload)

    send_job_to_producer(json["id"])

    {:noreply, state}
  end

  defp send_job_to_producer(id), do: GenStage.cast(Q.Producer, {:push_job, id})
end
