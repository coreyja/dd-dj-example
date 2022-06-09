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
        Datadog::Tracing.trace(
          'delayed_job_batch.run',
          continue_from: empty_digest,
          # start_at is ignored when a block is passed: https://github.com/DataDog/dd-trace-rb/blob/0646d7dd2d976e289da4eda43784a3687b35256d/lib/datadog/tracing/tracer.rb#L375=
          # And we need to pass a block to have access to the TraceOperation, and only the SpanOperation is returned from the block-less version
          # start_time: job.payload_object.batch_start_at.utc,
          service: 'delayed_job_batch',
          resource: 'SyncGraph'
        ) do |span, trace|
          span.instance_variable_set(:@id, job.payload_object.datadog_span_id)
          span.instance_variable_set(:@trace_id, job.payload_object.datadog_trace_id)
          # We need to set the start_time to our timestamp
          # We nil out the `duratoin_start` since its an either or thing with start_at, we don't want them both to be present
          # Source: https://github.com/DataDog/dd-trace-rb/blob/0646d7dd2d976e289da4eda43784a3687b35256d/lib/datadog/tracing/span_operation.rb#L194-L196=
          span.instance_variable_set(:@start_time, job.payload_object.batch_start_at.utc)
          span.instance_variable_set(:@duration_start, nil)
          # This doesn't seem needed for the data to send correctly
          trace.instance_variable_set(:@id, job.payload_object.datadog_trace_id)
        end
      end
    end
  end
end
