defmodule Q.ConsumerSupervisor do
  use ConsumerSupervisor

  def start_link(_init_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_initial) do
    children = [
      %{
        id: Q.Consumer,
        start: {Q.Consumer, :start_link, []},
        restart: :transient
      }
    ]

    ConsumerSupervisor.init(children,
      strategy: :one_for_one
    )
  end
end
