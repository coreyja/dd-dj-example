Datadog.configure do |c|
  c.tracing.enabled = true
  c.env = 'corey-local'

  c.logger.level = ::Logger::DEBUG

  c.tracing.instrument :delayed_job
end
