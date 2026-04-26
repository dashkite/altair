# Altair Test Coverage TODO

Ordered by Cost/Benefit Ratio.

- [x] [Remaining CRUD Methods](#remaining-crud-methods)
- [x] [Retry Exhaustion](#retry-exhaustion)
- [x] [Specific HTTP Retry Conditions](#specific-http-retry-conditions)
- [x] [Caching Logic](#caching-logic)
- [ ] [Offline Mode](#offline-mode)
- [ ] [Malformed Response / Sublime Errors](#malformed-response--sublime-errors)

## Notes

### Remaining CRUD Methods
- **Criticality:** Medium
- **Benefit:** Ensures protocol conformance for `put` and `delete`.
- **Strategy:** Extend the test server with `PUT` and `DELETE` routes for `/status/:code`. Verify that `put` yields `value` or `created`, and `delete` yields a `delete` event, following the manual generator advancement style.
- **Difficulty:** Low

### Retry Exhaustion
- **Criticality:** Medium
- **Benefit:** Prevents infinite loops and ensures graceful failure reporting.
- **Strategy:** Use a route that persistently returns `503 Service Unavailable`. Verify that Altair yields `retry` events until its internal limit (defined by `Retry.Counter` or `Retry.Backoff`) is reached, at which point it must yield a `failure` event and close the generator.
- **Difficulty:** Low

### Specific HTTP Retry Conditions
- **Criticality:** Low
- **Benefit:** Validates handling of standard congestion/timeout signals.
- **Strategy:** Implement routes for `429 Too Many Requests` and `504 Gateway Timeout`. Verify that these trigger the `retries.http.retry` strategy and yield the expected `retry` events before eventually succeeding or failing.
- **Difficulty:** Low

### Caching Logic
- **Criticality:** High
- **Benefit:** Verifies Altair's primary efficiency mechanism.
- **Strategy:** 
  - Verify that sequential requests for the same resource return the cached response without triggering network activity.
  - Verify the interaction between `writethru` (initial request state storage) and the final response.
  - Ensure the cache is invalidated or removed using `cache.remove` when a request is explicitly deleted or fails.
- **Difficulty:** Moderate (Requires careful management of `globalThis.caches`)

### Offline Mode
- **Criticality:** High
- **Benefit:** Ensures resilience in intermittent network environments.
- **Strategy:** Mock `globalThis.navigator.onLine`. Initiate a request while `false`, verify it enters the offline backoff loop, then toggle to `true` and verify the request completes successfully.
- **Difficulty:** Moderate

### Malformed Response / Sublime Errors
- **Criticality:** Low
- **Benefit:** Ensures system stability against unexpected or invalid server output.
- **Strategy:** Craft server responses that trigger `Sublime` validation failures (e.g., headers that fail the newly implemented `isArray` check). Verify that Altair's outer `catch` block catches these and yields a semantic `error` event with `scope: "request"`.
- **Difficulty:** Moderate
