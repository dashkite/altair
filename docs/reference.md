# Reference

## Altair

Altair encapsulates the request-response lifecycle, modeling it as a reactor. It depends on a provider (typically [Sublime](https://github.com/dashkite/sublime)) to define the "platonic" interface for HTTP requests and responses.

### make
$make: \to altair$

Creates a new Altair instance.

### use
$use: protocol \to altair$

Configures the Altair instance to use the provided protocol handler (e.g., a Sublime instance) for request and response processing.

### get
$get: specifier \to reactor$

Initiates an HTTP `get` request. The `specifier` is passed to the protocol's Request Builder.

### put
$put: specifier \to reactor$

Initiates an HTTP `put` request. Optimistically updates the write-through cache before dispatching.

### post
$post: specifier \to reactor$

Initiates an HTTP `post` request.

### delete
$delete: specifier \to reactor$

Initiates an HTTP `delete` request. Optimistically clears the write-through cache for the resource before dispatching.

## Reactor Events

Altair yields event objects with the following schema:
- `name`: Lowercase hyphenated string (e.g., `not-found`).
- `scope`: Either `"request"` or `"response"`.
- `request`: The `Sublime.Value` representing the request.
- `response`: The `Sublime.Value` representing the response (if available).
- `error`: The error object (for `error` events).

### cache-hit
`{ name: "cache-hit", scope: "request", request, response }`

Yielded when a valid entry is found in the write-through cache.

### authenticate
`{ name: "authenticate", scope: "request", challenges }`

Yielded when a `401 Unauthorized` response is received. The consumer should return `true` if authentication was handled and the request should be retried.

### retry
`{ name: "retry", scope: "request", request }`

Yielded before any retry attempt (including authentication, offline backoff, or HTTP retries).

### error
`{ name, scope: "request", error }`

Yielded when an unrecoverable error occurs (e.g., invalid URL, or network failure while offline). `name` is the normalized error message.

### success
`{ name: "success", scope: "response", request, response }`

Yielded when a successful response (2xx) is received.

### failure
`{ name: "failure", scope: "response", request, response }`

Yielded when a failure response (non-2xx) is received that was not handled by retries, or for fatal pre-dispatch errors.

### [status]
`{ name, scope: "response", request, response }`

Yielded for any response, where `name` is the normalized Sublime response description (e.g., `ok`, `not-found`, `created`).

## Lifecycle Sequences

Altair reactors yield a predictable sequence of events depending on the outcome of the request.

### Successful Cache Hit
1. `cache-hit` (scope: `request`)
2. `ok` (scope: `response`)
3. `success` (scope: `response`)
4. [terminates with response]

### Successful Network Request
1. `ok` (scope: `response`)
2. `success` (scope: `response`)
3. [terminates with response]

### Authentication Flow
1. `unauthorized` (scope: `response`)
2. `authenticate` (scope: `request`)
3. [waits for consumer signal]
4. `retry` (scope: `request`)
5. `ok` (scope: `response`)
6. `success` (scope: `response`)
7. [terminates with response]

### Offline Backoff
1. `retry` (scope: `request`)
2. [waits for network/backoff]
3. `retry` (scope: `request`)
...
4. `ok` (scope: `response`)
5. `success` (scope: `response`)
6. [terminates with response]
