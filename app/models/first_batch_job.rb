class FirstBatchJob
  include ActiveModel::Model

  attr_accessor :datadog_trace_id, :datadog_span_id, :batch_start_at

  def perform
    sleep rand(10)

    Delayed::Job.enqueue SecondBatchJob.new({datadog_trace_id:, datadog_span_id:, batch_start_at:})
  end
end
