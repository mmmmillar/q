defmodule Q.Producer do
  use GenStage
  require Logger

  def start_link(_init_args) do
    GenStage.start_link(__MODULE__, {:queue.new(), 0}, name: __MODULE__)
  end

  @impl true
  def init(initial) do
    {:producer, initial}
  end

  @impl true
  def handle_demand(demand, {backlog, existing_demand}) do
    # IO.inspect("Received demand: #{demand}, existing_demand: #{existing_demand}")

    case :queue.len(backlog) do
      0 ->
        {:noreply, [], {backlog, existing_demand + demand}}

      n ->
        n = min(demand, n)
        {items, backlog} = :queue.split(n, backlog)
        :queue.len(backlog) |> Q.Stats.set_waiting()
        {:noreply, :queue.to_list(items), {backlog, existing_demand + demand - n}}
    end
  end

  @impl true
  def handle_cast({:enqueue, item}, {backlog, 0}) do
    {:noreply, [], {:queue.in(item, backlog), 0}}
  end

  @impl true
  def handle_cast({:enqueue, item}, {backlog, existing_demand}) do
    IO.inspect("Received item: existing_demand: #{existing_demand}")

    backlog = :queue.in(item, backlog)
    {{:value, item}, backlog} = :queue.out(backlog)
    {:noreply, [item], {backlog, existing_demand - 1}}
  end

  def enqueue(item), do: GenStage.cast(__MODULE__, {:enqueue, item})
end
