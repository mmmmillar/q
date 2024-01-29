defmodule Q.Consumer do
  use GenStage

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{Q.ProducerConsumer, max_demand: 1, min_demand: 0}]}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, fn job_id ->
      IO.inspect("job #{job_id} received on consumer #{inspect(self())}")
    end)

    Enum.each(events, fn job_id ->
      Q.JobRecord.update(job_id, %{status: "in_progress"})
      IO.inspect("job #{job_id} started")

      ms = do_work()

      Q.JobRecord.update(job_id, %{status: "completed"})
      IO.inspect("job #{job_id} completed in #{ms}ms on consumer #{inspect(self())}")
    end)

    # As a consumer we never emit events
    {:noreply, [], state}
  end

  defp do_work do
    ms = 1000 + :rand.uniform(3000)
    Process.sleep(ms)
    ms
  end
end
