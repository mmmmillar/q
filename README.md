# Q

## Description

Q is a simple task queue system built using Elixir and Postgres. The aim was to model it on similar architectures common in cloud-based systems - something like this:

![Screenshot_20240115_185444](https://github.com/mmmmillar/q/assets/52740958/00fa37bc-0b9d-4b45-8b89-d24beeeeda90)

## Installation

Install dependencies:

```bash
mix deps.get
```

## Running

Run the task queue system using:

```bash
mix run --no-halt
```

The system will start and run continuously until you stop it manually.

# Q

To start your Phoenix server:

- Run `mix setup` to install and setup dependencies
- Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
