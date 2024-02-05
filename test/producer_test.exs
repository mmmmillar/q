defmodule TestConsumer do
  def start_link(producer) do
    GenStage.start_link(__MODULE__, {producer, self()})
  end

  def init({producer, owner}) do
    {:consumer, owner, subscribe_to: [{producer, max_demand: 1, min_demand: 0}]}
  end

  def handle_events(events, _from, owner) do
    send(owner, {:received, events})
    {:noreply, [], owner}
  end
end

defmodule Q.ProducerTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Q.Producer.start_link(:ok)
    {:ok, %{pid: pid}}
  end

  test "initialise new producer" do
    {backlog, existing_demand} = Q.Producer.state()

    assert :queue.to_list(backlog) == []
    assert existing_demand == 0
  end

  test "enqueue items when demand is 0" do
    Q.Producer.enqueue(1)
    Q.Producer.enqueue(2)
    Q.Producer.enqueue(3)

    {backlog, existing_demand} = Q.Producer.state()

    assert :queue.to_list(backlog) == [1, 2, 3]
    assert existing_demand == 0
  end

  test "enqueue items when existing demand", %{pid: pid} do
    TestConsumer.start_link(pid)
    Q.Producer.enqueue(1)
    Q.Producer.enqueue(2)
    Q.Producer.enqueue(3)

    {backlog, _} = Q.Producer.state()

    assert :queue.to_list(backlog) == [2, 3]
  end
end
