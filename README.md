# Altair

*Smart, reactive HTTP client*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Altair is a reactive HTTP client that transforms standard request/response cycles into a stream of semantic events. It encapsulates the request-response lifecycle and models it as a reactor, relying on a provider that implements the [Sublime](https://github.com/dashkite/sublime) interface for HTTP.

### Features

- Reactive Protocol: Methods return async generators yielding events like cache-hit, retry, authenticate, and normalized status names.
- Write-Through Caching: Optimistically updates the local cache on put and delete operations for immediate HX updates, assuming the put body matches the future get response.
- Collaborative Authentication: Yields an authenticate event, allowing consumers to handle credentials while Altair manages the retry logic.
- Offline Resilience: Automatically handles offline states with backoff retries.

## Installation

Use your favorite JavaScript package manager to install `@dashkite/altair`.

## Usage

Altair methods return an async generator (reactor). You can either consume the events or simply wait for the final response.

### Basic Usage

If you only care about the final response, you can use `yield from`:

```coffee
import { start } from "@dashkite/river"

# Perform a simple GET request
events = HTTP.get 
  origin: "https://api.example.com" 
  target: "/greeting"

# Collect all events; the last one is the response
start do ->
  response = yield from events
  console.log response.content
```

(In this example, `start` is a function that “runs” a reactor without reducing its products. Any comparable function from another library would work just as well.)

Of course, for a case like this, it’s often simpler to just use `fetch`. Altair’s real power is in its ability to support reactivity throught request-response lifecycle.

### Reactive Usage

Use `yield from` to delegate to the reactor within another generator, or iterate over it to handle lifecycle events.

```coffee
# Within another reactor or async generator
response = yield from HTTP.get 
  origin: "https://api.example.com" 
  target: "/greeting"

# Handling specific events
for await event from HTTP.get { origin, target: "/resource" }
  switch event.name
    when "cache-hit" then console.log "Serving from cache..."
    when "retry"     then console.log "Retrying request..."
    when "success"   then console.log "Request succeeded!"
```

### Handling Challenges

You can use a coroutine library like `@dashkite/reactive/event-coroutine` to handle specific lifecycle events like authentication challenges:

```coffee
import EventCoroutine from "@dashkite/reactive/event-coroutine"

response = await EventCoroutine
  .make HTTP.get
    origin: "https://api.example.com"
    target: "/authorized"
  .when "authenticate", -> 
    # Logic to provide credentials...
    true # Signal that we should retry
  .start()
```

Alternatively, you can manually iterate over the generator, passing `true` into `.next()` to signal that a challenge has been handled and the request should be retried.

## Configuration

Altair encapsulates the request-response lifecycle and models it as a reactor., while Sublime defines an idealized interface for HTTP. Thus, to use Altair, you must provide it with an object that implements the Sublime interfaces. Of course, you can use the Sublime module itself:

```coffee
import Altair from "@dashkite/altair"
import Sublime from "@dashkite/sublime"

# 1. Create a Sublime instance with your preferred rules
sublime = Sublime.make [ rulebase ]

# 2. Configure Altair to use it
HTTP = Altair.make().use sublime
```

## Other Resources

- [Reference](docs/reference.md)
- [Recipes](docs/recipes.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing Guide](docs/testing.md)

## Status

Not suitable for production use. Please report bugs and feature requests via the issue tracker.
