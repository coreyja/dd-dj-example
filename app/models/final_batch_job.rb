class FinalBatchJob
  include ActiveModel::Model

  attr_accessor :datadog_trace_id, :datadog_span_id, :batch_start_at

  def perform
    sleep rand(10)
  end
end
