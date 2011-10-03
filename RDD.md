# Notes on Pooled workers
Pool is responsible for creating supervised actors of a given class.

	# Feels a bit cumbersome
	Pool.supervise_as "foo_pool", "foo_pool", {:num_workers => 10, :worker_class => Foo}

Pool manages availability of nodes for work. Three attrs for tracking

	:available_workers
	:busy_workers
	:backlog

As workers are created, worker.name gets added to `@available_workers`.
Workers are selected via `Array#pop` on `@available_workers`
Workers are pushed into `@busy_workers` as `worker.name`.
Workers are sent work via registry lookup:

	Celluloid::Actor[:worker_name].work!(endpoint, message)

Possible ordering issue exists here. Should probably send messages to endpoint via same worker to ensure ordered delivery (or build per-endpoint queues?)

When worker is done, message is sent to `Pool#free_worker` with `worker.name`.
If there is a backlog, work is `Array#pop`'d and sent to same worker.
If there is no backlog, `worker.name` is pushed back into `@available_workers`.
Backlog is populated when `@available_workers.size == 0`


# Notes on flow

Pull current watchlist from Noah
Discover all known plugins (dummy, http, https...)
Spin up pools for each plugin
Attach to redis
Push message to appropriate pools

# Notes on notifying endpoints
- Are any watchers registered?
- Does the pattern match any of the registered watchers?
- If so, what's the scheme of those watchers?
- Do we know how to handle that scheme?
- Do we have a worker pool for it?
