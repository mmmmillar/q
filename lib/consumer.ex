defmodule Q.Consumer do
  alias Q.JobRecord
  use GenStage
  require Logger
  import Q.Constants

  @max_job_duration max_job_duration()

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter)
  end

  def init(state) do
    {:consumer, state, subscribe_to: [{Q.ProducerConsumer, max_demand: 1, min_demand: 0}]}
  end

  def handle_events(events, _from, state) do
    Enum.each(events, fn job_id ->
      task =
        Task.async(fn ->
          JobRecord.set_started(job_id)
          run_job()
        end)

      case Task.yield(task, @max_job_duration) || Task.shutdown(task) do
        {:ok, :job_run_failed} ->
          JobRecord.retry_job(job_id)

        {:ok, _result} ->
          JobRecord.set_completed(job_id)

        nil ->
          JobRecord.retry_job(job_id)
      end
    end)

    # As a consumer we never emit events
    {:noreply, [], state}
  end

  defp run_job do
    r = :rand.uniform(@max_job_duration)

    # add a couple of milliseconds to simulate timeout
    ms = 2 + r

    try do
      # simulate errors
      if r < 3, do: raise("EXCEPTION!!")

      Process.sleep(ms)
    rescue
      _error -> :job_run_failed
    end
  end
end
