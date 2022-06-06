# typed: false
# frozen_string_literal: true

class DelayedJobBatchesPlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, *args, &block|
      if job.payload_object.datadog_trace_id.present?
        begin
          ctx = Datadog.tracer.call_context

          span = Datadog::Span.new(
            Datadog.tracer,
            'delayed_job_batch.run',
            service: 'delayed_job_batch',
            trace_id: job.payload_object.datadog_trace_id
          )
          span.span_id = job.payload_object.datadog_span_id
          span.set_tag(Datadog::Ext::Runtime::TAG_PID, Process.pid)
          span.set_tag(Datadog::Ext::Runtime::TAG_ID, Datadog::Core::Environment::Identity.id)
          span.start(job.payload_object.batch_start_at.utc)

          ctx.add_span(span)

          block.call(job, *args)
        ensure
          # Actually get these traces to flush, without this we will miss all traces that happen in this batch :sadnerd:
          ctx.delete_span_if { |s| s.span_id == job.payload_object.datadog_span_id }
          Datadog.tracer.record(ctx)
        end
      else
        block.call(job, *args)
      end
    end

    lifecycle.after(:invoke_job) do |job, *_args|
      if job.payload_object.instance_of? FinalBatchJob
        context = Datadog::Context.new

        span = Datadog::Span.new(
          Datadog.tracer,
          'delayed_job_batch.run',
          service: 'delayed_job_batch',
          trace_id: job.payload_object.datadog_trace_id
        )
        span.span_id = job.payload_object.datadog_span_id
        span.set_tag(Datadog::Ext::Runtime::TAG_PID, Process.pid)
        span.set_tag(Datadog::Ext::Runtime::TAG_ID, Datadog::Core::Environment::Identity.id)
        span.start(job.payload_object.batch_start_at.utc)
        context.add_span(span)

        span.finish
      end
    end
  end
end
