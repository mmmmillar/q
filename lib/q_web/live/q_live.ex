defmodule QWeb.QLive do
  use QWeb, :live_view
  import Q.Constants

  @job_topic job_topic()

  def mount(_params, _session, socket) do
    QWeb.Endpoint.subscribe(@job_topic)

    {:ok,
     assign(socket, waiting: 0, in_progress: 0, completed: 0, failed: 0, errors: 0, timeouts: 0)}
  end

  def render(assigns) do
    ~H"""
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
       in_progress: socket.assigns[:in_progress] - 1
     )}
  end

  def handle_info(%{topic: @job_topic, event: "failed", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       failed: socket.assigns[:failed] + 1,
       in_progress: socket.assigns[:in_progress] - 1
     )}
  end

  def handle_info(%{topic: @job_topic, event: "error", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       errors: socket.assigns[:errors] + 1,
       in_progress: socket.assigns[:in_progress] - 1
     )}
  end

  def handle_info(%{topic: @job_topic, event: "timeout", payload: _job_id}, socket) do
    {:noreply,
     assign(socket,
       timeouts: socket.assigns[:timeouts] + 1,
       in_progress: socket.assigns[:in_progress] - 1
     )}
  end
end
