defmodule Q.Seeder do
  use GenServer
  require Logger
  import Q.Constants

  @batch_interval batch_interval()
  @batch_size batch_size()

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    seed()
    {:ok, %{}}
  end

  def handle_info(:lets_seed, state) do
    seed()
    {:noreply, state}
  end

  defp seed do
    now = NaiveDateTime.truncate(DateTime.to_naive(DateTime.utc_now()), :second)

    data =
      List.duplicate(
        %{
          inserted_at: now,
          updated_at: now
        },
        @batch_size
      )

    Q.Repo.insert_all(Q.JobRecord, data)

    Process.send_after(self(), :lets_seed, @batch_interval)
  end
end
