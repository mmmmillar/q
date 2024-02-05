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
