defmodule Q.Stats do
  use Agent

  def start_link(_init_args) do
    Agent.start_link(
      fn ->
        %{
          :jobs_waiting => 0,
          :jobs_completed => 0,
          :jobs_failed => 0,
          :consumer_count => 0
        }
      end,
      name: __MODULE__
    )
  end

  def increment_completed do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, :jobs_completed, &(&1 + 1))
    end)

    print()
  end

  def increment_failed do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, :jobs_failed, &(&1 + 1))
    end)

    print()
  end

  def increment_consumer_count do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, :consumer_count, &(&1 + 1))
    end)

    print()
  end

  def decrement_consumer_count do
    Agent.update(__MODULE__, fn state ->
      Map.update!(state, :consumer_count, &(&1 - 1))
    end)

    print()
  end

  def get_consumer_count do
    state = Agent.get(__MODULE__, & &1)
    Map.get(state, :consumer_count)
  end

  def set_waiting(count) do
    Agent.update(__MODULE__, fn state ->
      Map.replace(state, :jobs_waiting, count)
    end)

    print()
  end

  defp print do
    state = Agent.get(__MODULE__, & &1)
    IO.write("\r#{inspect(state)}")
  end
end
