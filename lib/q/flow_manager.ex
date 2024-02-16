defmodule Q.FlowManager do
  use GenServer

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, %{subscription: nil}, name: __MODULE__)
  end

  def init(initial) do
    {:ok, initial}
  end

  def handle_call(:stop_flow, _from, state) do
    GenStage.cancel(
      {Process.whereis(Q.ProducerConsumer), Map.get(state, :subscription)},
      :shutdown
    )

    GenStage.call(Q.ProducerConsumer, :drain)

    {:reply, :ok, Map.put(state, :subscription, nil)}
  end

  def handle_cast({:start_flow, max_demand}, state) do
    {:ok, subscription} =
      GenStage.sync_subscribe(Process.whereis(Q.ConsumerSupervisor),
        to: Q.ProducerConsumer,
        max_demand: max_demand,
        cancel: :transient
      )

    {:noreply, Map.put(state, :subscription, subscription)}
  end

  def handle_cast({:restart_flow, max_demand}, state) do
    {:ok, subscription} =
      GenStage.sync_resubscribe(
        Process.whereis(Q.ConsumerSupervisor),
        Map.get(state, :subscription),
        :normal,
        to: Q.ProducerConsumer,
        max_demand: max_demand,
        cancel: :transient
      )

    {:noreply, Map.put(state, :subscription, subscription)}
  end
end
