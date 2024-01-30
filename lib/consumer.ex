defmodule Q.Consumer do
  alias Q.JobRecord
  use GenStage
  require Logger

  @timeout 10

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{Q.ProducerConsumer, max_demand: 2, min_demand: 0}]}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, fn job_id ->
      Logger.info("job #{job_id} received on consumer #{inspect(self())}")
    end)

    Enum.each(events, fn job_id ->
      task =
        Task.async(fn ->
          JobRecord.set_started(job_id)
          run_job(job_id)
        end)

      case Task.yield(task, @timeout) || Task.shutdown(task) do
        {:ok, :job_run_failed} ->
          Logger.warning("job #{job_id} failed")
          JobRecord.retry_job(job_id)

        {:ok, _result} ->
          JobRecord.set_completed(job_id)

        nil ->
          Logger.warning("job #{job_id} timed out")
          JobRecord.retry_job(job_id)
      end
    end)

    # As a consumer we never emit events
    {:noreply, [], state}
  end

  defp run_job(job_id) do
    r = :rand.uniform(@timeout)
    ms = 1 + r

    try do
      if r == 1, do: raise("EXCEPTION!!")
      Process.sleep(ms)
      Logger.info("job #{job_id} completed in #{ms}ms on consumer #{inspect(self())}")
    rescue
      error ->
        Logger.error(error)
        :job_run_failed
    end
  end
end
