datadog_plugin_index = Delayed::Worker.plugins.index(Datadog::Contrib::DelayedJob::Plugin)
Delayed::Worker.plugins.insert(datadog_plugin_index, DelayedJobBatchesPlugin)
