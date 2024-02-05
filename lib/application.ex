defmodule Q.Application do
  use Application

  def start(_type, _args) do
    Logger.configure(level: :info)

    children = [
      Q.Stats,
      Q.Repo,
      Q.Producer,
      Q.ProducerConsumer,
      %{
        id: 1,
        start: {Q.Consumer, :start_link, [[]]}
      },
      %{
        id: 2,
        start: {Q.Consumer, :start_link, [[]]}
      },
      Q.DatabaseListener,
      Q.LoadManager,
      Q.Seeder
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Q.Supervisor)
  end
end
