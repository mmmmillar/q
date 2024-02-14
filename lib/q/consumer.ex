defmodule Q.Consumer do
  import Q.Constants

  @max_job_duration max_job_duration()
  @job_topic job_topic()

  def start_link(%{id: id, status: _status, retries: retries}) do
    Task.start_link(fn ->
      task = run_job(id)

      case Task.yield(task, @max_job_duration) || Task.shutdown(task) do
        {:ok, :job_run_failed} ->
          error(id, retries)

        {:ok, _result} ->
          success(id)

        nil ->
          timeout(id, retries)
      end
    end)
  end

  defp run_job(id) do
    Task.async(fn ->
      QWeb.Endpoint.broadcast(@job_topic, "in_progress", id)
      Q.JobRecord.set_in_progress(id)

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
    end)
  end

  defp success(id) do
    QWeb.Endpoint.broadcast(@job_topic, "completed", id)
    Q.JobRecord.set_completed(id)
  end

  defp error(id, retries) do
    cond do
      retries >= 3 ->
        QWeb.Endpoint.broadcast(@job_topic, "failed", id)
        Q.JobRecord.set_failed(id)

      true ->
        QWeb.Endpoint.broadcast(@job_topic, "error", id)
        Q.JobRecord.set_pending(id, retries + 1)
    end
  end

  defp timeout(id, retries) do
    cond do
      retries >= 3 ->
        QWeb.Endpoint.broadcast(@job_topic, "failed", id)
        Q.JobRecord.set_failed(id)

      true ->
        QWeb.Endpoint.broadcast(@job_topic, "timeout", id)
        Q.JobRecord.set_pending(id, retries + 1)
    end
  end
end
