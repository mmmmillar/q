defmodule Q.Producer do
  use GenStage

  def start_link(initial \\ []) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(job_ids) do
    {:producer, job_ids}
  end

  def handle_demand(demand, state) do
    {next_batch, tail} = Enum.split(state, demand)

    Q.Stats.set_waiting(Enum.count(tail))

    {:noreply, next_batch, tail}
  end

  def handle_cast({:push_job, job_id}, state) do
    {:noreply, [job_id], state ++ [job_id]}
  end
end
