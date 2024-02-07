defmodule Q.ConsumerSupervisor do
  use ConsumerSupervisor

  def start_link(_args) do
    {:ok, pid} = ConsumerSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    {:ok, pid}
  end

  def init(:ok) do
    children = [
      %{
        id: Q.Consumer,
        start: {Q.Consumer, :start_link, []},
        restart: :transient
      }
    ]

    ConsumerSupervisor.init(children,
      strategy: :one_for_one,
      subscribe_to: [
        {Q.ProducerConsumer, max_demand: 5}
      ]
    )
  end
end
