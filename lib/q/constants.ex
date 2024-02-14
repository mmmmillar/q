defmodule Q.Constants do
  @max_job_duration 2500
  @batch_interval 1000
  @batch_size 5

  def max_job_duration, do: @max_job_duration
  def batch_interval, do: @batch_interval
  def batch_size, do: @batch_size

  @job_topic "jobs"

  def job_topic, do: @job_topic
end
