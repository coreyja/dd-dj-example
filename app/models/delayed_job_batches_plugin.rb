# typed: false
# frozen_string_literal: true

class DelayedJobBatchesPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, *args, &block|
      if job.payload_object.datadog_trace_id.present?
        digest = Datadog::Tracing::TraceDigest.new(
          trace_id: job.payload_object.datadog_trace_id,
          span_id: job.payload_object.datadog_span_id,
          # This one took me AWHILE to figure out. Without this every trace was sampled I _think_ so it was never sent to DD
          trace_sampling_priority: 1,
        )
        Datadog::Tracing.continue_trace!(digest) do
          block.call(job, *args)
        end
      else
        block.call(job, *args)
      end
    end

    lifecycle.after(:invoke_job) do |job|
      if job.payload_object.instance_of? FinalBatchJob
        puts "About to send root span. span_id: #{job.payload_object.datadog_span_id} trace_id: #{job.payload_object.datadog_trace_id}"

        empty_digest = Datadog::Tracing::TraceDigest.new
        # start_at is ignored when a block is passed: https://github.com/DataDog/dd-trace-rb/blob/0646d7dd2d976e289da4eda43784a3687b35256d/lib/datadog/tracing/tracer.rb#L375=
        # So we use the block-less version
        # This does NOT give us access to the TraceOperation but it turns out we don't need it here
        # We actually need to set @trace_id on the span_op NOT @id on the trace_op
        # That seems to be what matters what getting things to send correctly
        span = Datadog::Tracing.trace(
          'delayed_job_batch.run',
          continue_from: empty_digest,
          start_time: job.payload_object.batch_start_at.utc,
          service: 'delayed_job_batch',
          resource: 'SyncGraph'
        )
        span.instance_variable_set(:@id, job.payload_object.datadog_span_id)
        span.instance_variable_set(:@trace_id, job.payload_object.datadog_trace_id)
        span.finish
      end
    end
  end
end
