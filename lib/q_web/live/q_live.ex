defmodule QWeb.QLive do
  use QWeb, :live_view
  import Q.Constants

  @job_topic job_topic()
  @config_topic config_topic()

  @max_demand 10

  def mount(_params, _session, socket) do
    QWeb.Endpoint.subscribe(@job_topic)
    QWeb.Endpoint.subscribe(@config_topic)

    batch_info = GenServer.call(Q.Seeder, :get_batch_info)
    max_job_duration = GenServer.call(Q.Producer, :get_max_job_duration)

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
         batch_size: batch_info[:batch_size],
         start_button_enabled: true,
         stop_button_enabled: false,
         max_demand: @max_demand,
         max_job_duration: max_job_duration
       }
     )}
  end

  def render(assigns) do
    ~H"""
    <div>
      <div>
        <button phx-click="start_processing" disabled={not @config[:start_button_enabled]}>
          Start
        </button>
        <button phx-click="stop_processing" disabled={not @config[:stop_button_enabled]}>
          Stop
        </button>
      </div>
      <form phx-submit="change_batch_interval">
        <label for="batch_interval">Batch Interval</label>
        <input type="number" name="batch_interval" value={@config[:batch_interval]} />
      </form>

      <form phx-submit="change_batch_size">
        <label for="batch_size">Batch Size</label>
        <input type="number" name="batch_size" value={@config[:batch_size]} />
      </form>

      <form phx-submit="change_max_demand">
        <label for="max_demand">Max Demand</label>
        <input type="number" name="max_demand" value={@config[:max_demand]} />
      </form>

      <form phx-submit="change_max_job_duration">
        <label for="max_demand">Max Job Duration</label>
        <input type="number" name="max_job_duration" value={@config[:max_job_duration]} />
      </form>
    </div>

    <div class="dashboard-card">
      <%= @config |> Poison.encode!() %>
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

  def handle_info(
        %{topic: @config_topic, event: "max_demand", payload: max_demand},
        socket
      ) do
    GenServer.cast(Q.FlowManager, {:restart_flow, max_demand})

    {:noreply,
     assign(socket,
       config: Map.put(socket.assigns[:config], :max_demand, max_demand)
     )}
  end

  def handle_info(
        %{topic: @config_topic, event: "max_job_duration", payload: max_job_duration},
        socket
      ) do
    {:noreply,
     assign(socket, config: Map.put(socket.assigns[:config], :max_job_duration, max_job_duration))}
  end

  def handle_event("start_processing", _params, socket) do
    GenServer.cast(Q.FlowManager, {:start_flow, Map.get(socket.assigns[:config], :max_demand)})

    {:noreply,
     assign(socket,
       config:
         Map.put(
           Map.put(socket.assigns[:config], :start_button_enabled, false),
           :stop_button_enabled,
           true
         )
     )}
  end

  def handle_event("stop_processing", _params, socket) do
    GenServer.call(Q.FlowManager, :stop_flow)

    {:noreply,
     assign(socket,
       config:
         Map.put(
           Map.put(socket.assigns[:config], :start_button_enabled, true),
           :stop_button_enabled,
           false
         )
     )}
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

  def handle_event("change_max_demand", params, socket) do
    QWeb.Endpoint.broadcast(@config_topic, "max_demand", String.to_integer(params["max_demand"]))

    {:noreply, socket}
  end

  def handle_event("change_max_job_duration", params, socket) do
    GenServer.cast(
      Q.Producer,
      {:update_max_job_duration, String.to_integer(params["max_job_duration"])}
    )

    {:noreply, socket}
  end
end
