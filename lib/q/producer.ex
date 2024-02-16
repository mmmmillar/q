defmodule Q.Producer do
  use GenStage
  import Q.Constants

  @job_topic job_topic()

  def start_link(_init_args) do
    GenStage.start_link(__MODULE__, {:queue.new(), 0}, name: __MODULE__)
  end

  @impl true
  def init(initial) do
    {:producer, initial}
  end

  @impl true
  def handle_demand(demand, {backlog, existing_demand}) do
    case :queue.len(backlog) do
      0 ->
        {:noreply, [], {backlog, existing_demand + demand}}

      n ->
        n = min(demand, n)
        {items, backlog} = :queue.split(n, backlog)
        broadcast_backlog_size(backlog)
        {:noreply, :queue.to_list(items), {backlog, existing_demand + demand - n}}
    end
  end

  @impl true
  def handle_cast({:enqueue, job}, {backlog, 0}) do
    backlog = :queue.in(job, backlog)
    broadcast_backlog_size(backlog)
    {:noreply, [], {backlog, 0}}
  end

  @impl true
  def handle_cast({:enqueue, job}, {backlog, existing_demand}) do
    backlog = :queue.in(job, backlog)
    {{:value, job}, backlog} = :queue.out(backlog)

    {:noreply, [job], {backlog, existing_demand - 1}}
  end

  @impl true
  def handle_call(:remove_demand, _from, {backlog, _existing_demand}) do
    {:reply, 0, [], {backlog, 0}}
  end

  def enqueue(job), do: GenStage.cast(__MODULE__, {:enqueue, job})

  def broadcast_backlog_size(backlog),
    do: QWeb.Endpoint.broadcast(@job_topic, "waiting", :queue.len(backlog))
end
