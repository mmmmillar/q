defmodule Q.Producer do
  use GenStage
  import Q.Constants

  @job_topic job_topic()
  @config_topic config_topic()

  def start_link(init_args) do
    GenStage.start_link(
      __MODULE__,
      %{
        backlog: :queue.new(),
        existing_demand: 0,
        max_job_duration: init_args[:max_job_duration]
      },
      name: __MODULE__
    )
  end

  @impl true
  def init(initial) do
    {:producer, initial}
  end

  @impl true
  def handle_demand(demand, %{:backlog => backlog, :existing_demand => existing_demand} = state) do
    case :queue.len(backlog) do
      0 ->
        {:noreply, [], Map.put(state, :existing_demand, existing_demand + demand)}

      n ->
        n = min(demand, n)
        {items, backlog} = :queue.split(n, backlog)

        broadcast_backlog_size(backlog)

        state = Map.put(state, :backlog, backlog)
        state = Map.put(state, :existing_demand, existing_demand + demand - n)

        {:noreply, :queue.to_list(items), state}
    end
  end

  @impl true
  def handle_cast(
        {:enqueue, job},
        %{:backlog => backlog, :existing_demand => 0, :max_job_duration => max_job_duration} =
          state
      ) do
    job = Map.put(job, :duration, get_duration(max_job_duration))
    job = Map.put(job, :max_job_duration, max_job_duration)
    backlog = :queue.in(job, backlog)

    broadcast_backlog_size(backlog)

    {:noreply, [], Map.put(state, :backlog, backlog)}
  end

  @impl true
  def handle_cast(
        {:enqueue, job},
        %{
          :backlog => backlog,
          :existing_demand => existing_demand,
          :max_job_duration => max_job_duration
        } =
          state
      ) do
    job = Map.put(job, :duration, get_duration(max_job_duration))
    job = Map.put(job, :max_job_duration, max_job_duration)
    backlog = :queue.in(job, backlog)

    {{:value, job}, backlog} = :queue.out(backlog)

    state = Map.put(state, :backlog, backlog)
    state = Map.put(state, :existing_demand, existing_demand - 1)

    {:noreply, [job], state}
  end

  @impl true
  def handle_cast({:update_max_job_duration, max_job_duration}, state) do
    QWeb.Endpoint.broadcast(@config_topic, "max_job_duration", max_job_duration)
    {:noreply, [], Map.put(state, :max_job_duration, max_job_duration)}
  end

  @impl true
  def handle_call(:get_max_job_duration, _from, state) do
    {:reply, state[:max_job_duration], [], state}
  end

  defp broadcast_backlog_size(backlog),
    do: QWeb.Endpoint.broadcast(@job_topic, "waiting", :queue.len(backlog))

  defp get_duration(max_job_duration), do: :rand.uniform(max_job_duration)
end
