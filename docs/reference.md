# Reference

## Core Concepts

Before exploring the API, it is helpful to understand the core structures that Altair relies upon across its methods.

### Specifiers

Altair HTTP methods accept a `specifier`. A specifier is a data structure, typically a plain object, that describes the desired HTTP request. Common properties include `origin`, `target`, `headers`, and `content`. Altair passes this specifier directly to the underlying protocol's Request Builder (such as `Sublime.Request.Builder`) to construct a formal request representation.

### Reactors

Rather than returning a standard Promise, Altair methods return a `reactor`. A reactor is an asynchronous generator that yields a stream of discrete semantic events throughout the lifecycle of the request. By yielding events instead of just the final response, a reactor allows consumers to observe and interact with intermediate states, such as cache hits, authentication challenges, and offline retries.

### Event Schema

When a reactor yields an event, it always follows a consistent schema:

- `name`: A lowercase, hyphenated string representing the event type or status (e.g., `not-found`, `cache-hit`).
- `scope`: A string indicating the lifecycle phase, constrained to either `"request"` or `"response"`.
- `request`: The formalized request object (e.g., a `Sublime.Value`).
- `response`: The formalized response object, present only if a response has been received.
- `error`: The caught error object, present only for `error` events.

## Altair

The `Altair` class provides the primary interface for initiating reactive HTTP requests. It relies on a protocol provider, typically [Sublime](https://github.com/dashkite/sublime), to define the underlying request and response structures.

### make
$make: \to altair$

Creates and returns a new, inactive Altair instance. You must configure the instance with a protocol provider before you can dispatch requests.

```coffeescript
import Altair from "@dashkite/altair"

client = Altair.make()
```

### use
$use: protocol \to altair$

Configures the Altair instance to use the provided `protocol` handler for all request and response processing. This method returns the Altair instance itself, allowing for method chaining during initialization.

```coffeescript
import Altair from "@dashkite/altair"
import Sublime from "@dashkite/sublime"

HTTP = Altair.make().use Sublime.make()
```

### get
$get: specifier \to reactor$

Initiates an HTTP `get` request to retrieve a resource. Altair checks its local write-through cache before dispatching the network request, yielding a `cache-hit` event if a valid entry exists.

```coffeescript
events = HTTP.get 
  origin: "https://api.example.com"
  target: "/users/1"
```

### put
$put: specifier \to reactor$

Initiates an HTTP `put` request to replace a resource. Altair optimistically updates the local write-through cache with the request's content immediately before dispatching the request to the network.

```coffeescript
events = HTTP.put 
  origin: "https://api.example.com"
  target: "/users/1"
  content: { name: "Alice" }
```

### post
$post: specifier \to reactor$

Initiates an HTTP `post` request to create a new resource or submit data. Unlike `put`, this method does not populate the write-through cache because the resulting resource identifier or state is determined by the server.

```coffeescript
events = HTTP.post 
  origin: "https://api.example.com"
  target: "/users"
  content: { name: "Bob" }
```

### delete
$delete: specifier \to reactor$

Initiates an HTTP `delete` request to remove a resource. Altair optimistically clears the corresponding entry from the local write-through cache immediately before dispatching the network request.

```coffeescript
events = HTTP.delete 
  origin: "https://api.example.com"
  target: "/users/1"
```

### patch
$patch: specifier \to reactor$

Initiates an HTTP `patch` request to partially modify an existing resource. 

```coffeescript
events = HTTP.patch 
  origin: "https://api.example.com"
  target: "/users/1"
  content: { status: "active" }
```

### head
$head: specifier \to reactor$

Initiates an HTTP `head` request. This behaves exactly like a `get` request, but the server omits the response body, making it useful for checking headers or verifying resource existence.

```coffeescript
events = HTTP.head 
  origin: "https://api.example.com"
  target: "/users/1"
```

### options
$options: specifier \to reactor$

Initiates an HTTP `options` request to describe the communication options available for the target resource.

```coffeescript
events = HTTP.options 
  origin: "https://api.example.com"
  target: "/users/1"
```

## Reactor Events

The following section details the specific events that an Altair reactor may yield during the request lifecycle.

### cache-hit
`{ name: "cache-hit", scope: "request", request, response }`

Yielded when a valid entry is found in the write-through cache before a network dispatch occurs.

### cache-miss
`{ name: "cache-miss", scope: "request", request }`

Yielded when no valid entry is found in the write-through cache, signaling that a network request is imminent.

### authenticate
`{ name: "authenticate", scope: "request", challenges }`

Yielded when a `401 Unauthorized` response is received. The consumer should return `true` to the generator if authentication was handled and the request should be retried.

### retry
`{ name: "retry", scope: "request", request }`

Yielded immediately before any retry attempt, including authentication rebuilds, offline backoff attempts, or HTTP protocol retries.

### error
`{ name, scope: "request", error }`

Yielded when an unrecoverable internal error occurs, such as an invalid URL or a network failure while offline. The `name` is the normalized error message.

### success
`{ name: "success", scope: "response", request, response }`

Yielded when a successful HTTP response (2xx) is received and processed.

### failure
`{ name: "failure", scope: "response", request, response }`

Yielded when a failure HTTP response (non-2xx) is received that was not handled by retries, or for fatal pre-dispatch errors.

### [status]
`{ name, scope: "response", request, response }`

Yielded for every received response, where `name` is the normalized Sublime response description (e.g., `ok`, `not-found`, `created`).
