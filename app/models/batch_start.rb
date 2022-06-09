class BatchStart
  def self.start
    Delayed::Job.enqueue(
      FirstBatchJob.new(
        datadog_span_id: Datadog::Core::Utils.next_id,
        datadog_trace_id: Datadog::Core::Utils.next_id,
        batch_start_at: Time.zone.now
      )
    )
  end
end
