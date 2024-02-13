defmodule Q.Consumer do
  import Q.Constants

  @max_job_duration max_job_duration()

  def start_link(job_id) do
    Task.start_link(fn ->
      Q.Stats.increment_consumer_count()

      task =
        Task.async(fn ->
          Q.JobRecord.set_started(job_id)
          run_job()
        end)

      case Task.yield(task, @max_job_duration) || Task.shutdown(task) do
        {:ok, :job_run_failed} ->
          Q.JobRecord.retry_job(job_id)

        {:ok, _result} ->
          Q.JobRecord.set_completed(job_id)

        nil ->
          Q.JobRecord.retry_job(job_id)
      end

      Q.Stats.decrement_consumer_count()
    end)
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
