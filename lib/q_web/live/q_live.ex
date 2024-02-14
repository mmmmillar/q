defmodule QWeb.QLive do
  use QWeb, :live_view
  import Q.Constants

  @job_topic job_topic()
  @config_topic config_topic()

  def mount(_params, _session, socket) do
    QWeb.Endpoint.subscribe(@job_topic)
    QWeb.Endpoint.subscribe(@config_topic)

    batch_info = GenServer.call(Q.Seeder, :get_batch_info)

    {:ok,
     assign(socket,
       waiting: 0,
       in_progress: 0,
       completed: 0,
       failed: 0,
       errors: 0,
       timeouts: 0,
       config: %{
         batch_interval: batch_info[:batch_interval],
         batch_size: batch_info[:batch_size]
       }
     )}
  end

  def render(assigns) do
    ~H"""
    <div>
      <form phx-submit="change_batch_interval">
        <label for="batch_interval">Batch Interval</label>
        <input type="number" name="batch_interval" value={@config[:batch_interval]} />
      </form>

      <form phx-submit="change_batch_size">
        <label for="batch_size">Batch Size</label>
        <input type="number" name="batch_size" value={@config[:batch_size]} />
      </form>
    </div>

    <div class="dashboard-card">
      <%= @config |> m2s %>
    </div>

    <div class="dashboard-card">
      <h2><%= @waiting %></h2>
      <p>Waiting</p>
    </div>

    <div class="dashboard-card">
      <h2><%= @in_progress %></h2>
      <p>In Progress</p>
    </div>

    <div class="dashboard-card">
      <h2><%= @completed %></h2>
      <p>Completed</p>
    </div>

    <div class="dashboard-card">
      <h2><%= @failed %></h2>
      <p>Failed</p>
    </div>

    <div class="dashboard-card">
      <h2><%= @errors %></h2>
      <p>Errors</p>
    </div>

    <div class="dashboard-card">
      <h2><%= @timeouts %></h2>
      <p>Timeouts</p>
    </div>
    """
  end

  def handle_info(%{topic: @job_topic, event: "waiting", payload: waiting}, socket) do
    {:noreply, assign(socket, waiting: waiting)}
  end

  def handle_info(%{topic: @job_topic, event: "in_progress", payload: _job_id}, socket) do
    {:noreply, assign(socket, in_progress: socket.assigns[:in_progress] + 1)}
  end

  def handle_info(%{topic: @job_topic, event: "completed", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       completed: socket.assigns[:completed] + 1,
       in_progress: max(0, socket.assigns[:in_progress] - 1)
     )}
  end

  def handle_info(%{topic: @job_topic, event: "failed", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       failed: socket.assigns[:failed] + 1,
       in_progress: max(0, socket.assigns[:in_progress] - 1)
     )}
  end

  def handle_info(%{topic: @job_topic, event: "error", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       errors: socket.assigns[:errors] + 1,
       in_progress: max(0, socket.assigns[:in_progress] - 1)
     )}
  end

  def handle_info(%{topic: @job_topic, event: "timeout", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       timeouts: socket.assigns[:timeouts] + 1,
       in_progress: max(0, socket.assigns[:in_progress] - 1)
     )}
  end

  def handle_info(
        %{topic: @config_topic, event: "batch_interval", payload: batch_interval},
        socket
      ) do
    {:noreply,
     assign(socket, config: Map.put(socket.assigns[:config], :batch_interval, batch_interval))}
  end

  def handle_info(
        %{topic: @config_topic, event: "batch_size", payload: batch_size},
        socket
      ) do
    {:noreply, assign(socket, config: Map.put(socket.assigns[:config], :batch_size, batch_size))}
  end

  def handle_event("change_batch_interval", params, socket) do
    GenServer.cast(
      Q.Seeder,
      {:update_batch_interval, String.to_integer(params["batch_interval"])}
    )

    {:noreply, socket}
  end

  def handle_event("change_batch_size", params, socket) do
    GenServer.cast(
      Q.Seeder,
      {:update_batch_size, String.to_integer(params["batch_size"])}
    )

    {:noreply, socket}
  end

  defp m2s(map) do
    {:ok, str} = map |> Poison.encode()
    str
  end
end
