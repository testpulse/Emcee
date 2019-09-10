# Change Log

All notable changes to this project will be documented in this file.

## 2019-09-10

### Added

- New Graphite metric `queue.worker.status.<worker_name>.[alive|blocked|notRegistered|silent]` allows you to track the statuses of your workers.

### Changed

- Updated the way how workers report test results back to the queue. Report request hardcoded timeout of 10 seconds has been removed. Workers now rely on the `NSURLTask` API default timeouts. This allows the queue to process network request for as long as it would need. This also fixes an issue when worker decides that such request has timed out, it will re-attempt to report test results again, making the queue block the worker.

## 2019-09-06

### Changed

- When you attempt to run tests using `runTestsOnRemoteQueue` command, and if shared queue is not running yet, previously Emcee would start the queue on a remote machine and then will deploy and start workers for that queue from inside `runTestsOnRemoteQueue` command. Now the behaviour has changed: once started, the queue will deploy and start workers for itself independently from `runTestsOnRemoteQueue` command. 

- Emcee now applies a shared lock to a whole file cache (`~/Library/Caches`) when it unzips downloaded files. Previously multiple Emcee processes may run a race for the same zip file.

### Removed

- Removed `--analytics-configuration` and `--worker-destinations-location` arguments from `runTestsOnRemoteQueue` command. Now you have to pass them via `--queue-server-configuration-location` JSON file. Corresponding `QueueServerRunConfiguration` Swift model has been updated to include new `workerDeploymentDestinations` field, and `analyticsConfiguration` field has been around for a while.