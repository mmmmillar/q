defmodule Q.Constants do
  @max_job_duration 15
  @batch_interval 1000
  @batch_size 100
  @backlog_threshold 1000
  @initial_consumer_count 2

  def max_job_duration, do: @max_job_duration
  def batch_interval, do: @batch_interval
  def batch_size, do: @batch_size
  def backlog_threshold, do: @backlog_threshold
  def initial_consumer_count, do: @initial_consumer_count
end
