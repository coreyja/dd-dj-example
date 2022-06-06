## Example of Distributed Trace via DB Reads and Writes

This is an example Repo to show how we have wired up a way to use Distributed Tracing
to 'batch' a group of Delayed Jobs via a DelayedJob Plugin and some careful working of the Datadog
SDK

Entrypoint: `BatchStart.start`
This will kick off the 'first' job in our batch, passing in a generated trace and span id and a start time

Jobs: `FirstBatchJob`, `SecondBatchJob`, `FinalBatchJob`
These simply sleep for a random amount of time, and then enqueue the next job in the queue passing down all the params

Actual Meat of the Demo: `DelayedJobBatchPlugin`
This implements a DelayedJob plugin that plays with the traces such that any job with the required attributes is put into a 'batch'
And then after the `FinalBatchJob` runs we actually send the span for the 'virtual' batch

### Differences from my `real` code

0. This demo passes the params to each job manually. In real life I save these to a different DB table, and associate that to each job
0. In this demo we don't 'fan-out' in the jobs and enqueue more than 1 ever, but we do in real life. Other code manages knowning when the fan-out is complete to actually send the batch to DD
0. We are using Postgres and this is SQLite [can't imagine that matters]

Besides that this is basically a copy-paste of my existing Pre-1.0 code trimmed down to its most minimal form
