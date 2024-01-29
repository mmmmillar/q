defmodule Q do
  use GenServer

  def handle_call(:queue, _from, state), do: {:reply, state, state}

  def handle_call(:dequeue, _from, []), do: {:reply, nil, []}

  def handle_call(:dequeue, _from, [head | tail]), do: {:reply, head, tail}

  def handle_cast({:enqueue, value}, state), do: {:noreply, state ++ [value]}

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state), do: {:ok, state}

  def queue do
    GenServer.call(__MODULE__, :queue)
  end

  def dequeue do
    GenServer.call(__MODULE__, :dequeue)
  end

  def enqueue(value) do
    GenServer.cast(__MODULE__, {:enqueue, value})
  end
end
