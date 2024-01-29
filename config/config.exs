import Config

config :q, Q.Repo,
  database: "q",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :q, ecto_repos: [Q.Repo]
