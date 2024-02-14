defmodule Q.Seeder do
  use GenServer
  import Q.Constants

  @config_topic config_topic()

  def start_link(_init_args) do
    GenServer.start_link(
      __MODULE__,
      %{batch_interval: batch_interval(), batch_size: batch_size()},
      name: __MODULE__
    )
  end

  @spec init(nil | maybe_improper_list() | map()) :: {:ok, nil | maybe_improper_list() | map()}
  def init(initial) do
    seed(initial)

    {:ok, initial}
  end

  def handle_info(:seed, state) do
    seed(state)
    {:noreply, state}
  end

  def handle_cast({:update_batch_interval, batch_interval}, state) do
    QWeb.Endpoint.broadcast(@config_topic, "batch_interval", batch_interval)
    {:noreply, Map.put(state, :batch_interval, batch_interval)}
  end

  def handle_cast({:update_batch_size, batch_size}, state) do
    QWeb.Endpoint.broadcast(@config_topic, "batch_size", batch_size)
    {:noreply, Map.put(state, :batch_size, batch_size)}
  end

  def handle_call(:get_batch_info, _from, state) do
    {:reply, state, state}
  end

  defp seed(state) do
    now =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    List.duplicate(
      %{
        inserted_at: now,
        updated_at: now
      },
      state[:batch_size]
    )
    |> Q.JobRecord.insert_batch()

    Process.send_after(self(), :seed, state[:batch_interval])
  end
end
