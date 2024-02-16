defmodule Q.ProducerConsumer do
  use GenStage

  def start_link(_init_args) do
    GenStage.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(initial) do
    {:producer_consumer, initial, subscribe_to: [{Q.Producer, max_demand: 1}]}
  end

  def handle_subscribe(:producer, _opts, from, state) do
    GenStage.ask(from, 1)

    {:manual, Map.put(state, :from, from)}
  end

  def handle_subscribe(:consumer, _opts, _from, state) do
    {:automatic, state}
  end

  def handle_info(:demand_job, state) do
    GenStage.ask(state[:from], 1)

    {:noreply, [], state}
  end

  def handle_events(jobs, _from, state) do
    send(self(), :demand_job)

    {:noreply, jobs, state}
  end
end
