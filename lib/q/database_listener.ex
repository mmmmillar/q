defmodule Q.DatabaseListener do
  use GenServer

  @channel "new_job"

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_initial) do
    {:ok, pid} =
      Q.Repo.config() |> Keyword.merge(pool_size: 1) |> Postgrex.Notifications.start_link()

    {:ok, ref} = Postgrex.Notifications.listen(pid, @channel)

    {:ok, {pid, ref}}
  end

  def handle_info({:notification, _pid, _ref, @channel, payload}, state) do
    {:ok, json} = Poison.decode(payload)
    GenStage.cast(Q.Producer, {:enqueue, json["id"]})
    {:noreply, state}
  end
end
