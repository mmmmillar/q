defmodule Q.Seeder do
  use GenServer
  require Logger
  import Q.Constants

  @batch_interval batch_interval()
  @batch_size batch_size()

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(_initial) do
    seed()
    {:ok, []}
  end

  def handle_info(:lets_seed, state) do
    seed()
    {:noreply, state}
  end

  defp seed do
    now =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    List.duplicate(
      %{
        inserted_at: now,
        updated_at: now
      },
      @batch_size
    )
    |> Q.JobRecord.insert_batch()

    Process.send_after(self(), :lets_seed, @batch_interval)
  end
end
