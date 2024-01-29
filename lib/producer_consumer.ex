defmodule Q.ProducerConsumer do
  use GenStage

  def start_link(_initial) do
    GenStage.start_link(__MODULE__, :state_doesnt_matter, name: __MODULE__)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [Q.Producer]}
  end

  def handle_events(events, _from, state) do
    # producer "middleware" - do things like filter before passing on to consumer
    {:noreply, events, state}
  end
end
