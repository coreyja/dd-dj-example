Datadog.configure do |c|
  c.tracer enabled: true
  c.tracer env: 'corey-local'

  c.use :delayed_job
end
