# Reference

## Altair

### make
$make: \to altair$

Creates a new Altair instance.

### use
$use: sublime \to altair$

Configures the Altair instance to use the provided Sublime instance for request and response processing.

### get
$get: specifier \to reactor$

Initiates an HTTP `GET` request. The `specifier` is passed to the Sublime Request Builder.

### put
$put: specifier \to reactor$

Initiates an HTTP `PUT` request.

### post
$post: specifier \to reactor$

Initiates an HTTP `POST` request.

### delete
$delete: specifier \to reactor$

Initiates an HTTP `DELETE` request.

## Reactor Events

Altair yields the following events:

### error
`{ name: "error", error }`

Yielded when an unrecoverable error occurs (e.g., network failure while offline).

### authenticate
`{ name: "authenticate", challenges }`

Yielded when a `401 Unauthorized` response is received. The consumer should return `true` if authentication was handled and the request should be retried.

### retry
`{ name: "retry", request }`

Yielded before retrying a request. The consumer can provide a modified request to be used for the retry.

### success
`{ name: "success", request, response }`

Yielded when a successful response (2xx) is received.

### failure
`{ name: "failure", request, response }`

Yielded when a failure response (non-2xx) is received that was not handled by retries.

### [status]
`{ name: status, request, response }`

Yielded for any response, where `status` is the Sublime response description (e.g., "ok", "not found", "created").
