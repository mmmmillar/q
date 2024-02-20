defmodule Q.Consumer do
  import Q.Constants

  @job_topic job_topic()

  def start_link(%{
        id: id,
        status: _status,
        retries: retries,
        duration: duration,
        max_job_duration: max_job_duration
      }) do
    Task.start_link(fn ->
      task = run_job(id, duration, max_job_duration)

      case Task.yield(task, max_job_duration) || Task.shutdown(task) do
        {:ok, :job_run_failed} ->
          error(id, retries)

        {:ok, _result} ->
          success(id)

        nil ->
          timeout(id, retries)
      end
    end)
  end

  defp run_job(id, duration, max_job_duration) do
    Task.async(fn ->
      QWeb.Endpoint.broadcast(@job_topic, "in_progress", id)
      Q.JobRecord.set_in_progress(id)

      # # simulate timeouts 15% of the time
      ms = ceil(max_job_duration * 0.15) + duration

      try do
        # simulate errors 4% of the time
        if duration < max_job_duration * 0.04, do: raise("EXCEPTION!!")

        Process.sleep(ms)
      rescue
        _error -> :job_run_failed
      end
    end)
  end

  defp success(id) do
    Q.JobRecord.set_completed(id)
    QWeb.Endpoint.broadcast(@job_topic, "completed", id)
  end

  defp error(id, retries) do
    cond do
      retries >= 3 ->
        Q.JobRecord.set_failed(id)
        QWeb.Endpoint.broadcast(@job_topic, "failed", id)

      true ->
        Q.JobRecord.set_pending(id, retries + 1)
        QWeb.Endpoint.broadcast(@job_topic, "error", id)
    end
  end

  defp timeout(id, retries) do
    cond do
      retries >= 3 ->
        Q.JobRecord.set_failed(id)
        QWeb.Endpoint.broadcast(@job_topic, "failed", id)

      true ->
        Q.JobRecord.set_pending(id, retries + 1)
        QWeb.Endpoint.broadcast(@job_topic, "timeout", id)
    end
  end
end
