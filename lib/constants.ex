defmodule Q.Constants do
  @max_job_duration 15
  @batch_interval 15
  @batch_size 3

  def max_job_duration, do: @max_job_duration
  def batch_interval, do: @batch_interval
  def batch_size, do: @batch_size
end
