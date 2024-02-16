defmodule Q.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @max_job_duration 2500
  @batch_interval 1000
  @batch_size 5

  @impl true
  def start(_type, _args) do
    Logger.configure(level: :info)

    children = [
      QWeb.Telemetry,
      Q.Repo,
      {DNSCluster, query: Application.get_env(:q, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Q.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Q.Finch},
      QWeb.Endpoint,
      {Q.Producer, max_job_duration: @max_job_duration},
      Q.ProducerConsumer,
      Q.ConsumerSupervisor,
      Q.FlowManager,
      Q.DatabaseListener,
      {Q.Seeder, batch_interval: @batch_interval, batch_size: @batch_size}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Q.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
