defmodule Q.ConsumerSupervisor do
  use ConsumerSupervisor

  def start_link(init_args) do
    ConsumerSupervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  def init(initial) do
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
        {Q.ProducerConsumer, max_demand: initial[:max_demand]}
      ]
    )
  end
end
