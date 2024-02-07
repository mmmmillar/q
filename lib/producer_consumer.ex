defmodule Q.ProducerConsumer do
  use GenStage

  def start_link(_init_args) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(initial) do
    {:producer_consumer, initial, subscribe_to: [{Q.Producer, max_demand: 1}]}
  end

  def handle_events(events, _from, state) do
    # producer "middleware" - do things like filter before passing on to consumer
    IO.inspect("passing events to consumer: #{inspect(events)}")
    {:noreply, events, state}
  end
end
