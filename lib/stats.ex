defmodule Q.Stats do
  use Agent

  def start_link(_) do
    Agent.start_link(
      fn ->
        %{
          :jobs_completed => 0,
          :jobs_failed => 0,
          :jobs_waiting => 0
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
