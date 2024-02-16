defmodule Q.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

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
      Q.Producer,
      Q.ProducerConsumer,
      Q.ConsumerSupervisor,
      Q.DatabaseListener,
      Q.Seeder
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
