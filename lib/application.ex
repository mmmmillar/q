defmodule Q.Application do
  use Application
  require Logger

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Logger.configure(level: :info)

    children = [
      Q.Stats,
      Q.Repo,
      {Q.Producer, []},
      {Q.ProducerConsumer, []},
      %{
        id: 1,
        start: {Q.Consumer, :start_link, [[]]}
      },
      %{
        id: 2,
        start: {Q.Consumer, :start_link, [[]]}
      },
      %{
        id: 3,
        start: {Q.Consumer, :start_link, [[]]}
      },
      %{
        id: 4,
        start: {Q.Consumer, :start_link, [[]]}
      },
      %{
        id: 5,
        start: {Q.Consumer, :start_link, [[]]}
      },
      %{
        id: 6,
        start: {Q.Consumer, :start_link, [[]]}
      },
      Q.DatabaseListener,
      Q.Seeder
    ]

    opts = [strategy: :one_for_one, name: Q.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
