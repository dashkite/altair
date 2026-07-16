# Altair

*Smart, reactive HTTP client*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

Altair is a reactive HTTP client that transforms standard request/response cycles into a stream of semantic events. It encapsulates the request-response lifecycle and models it as a reactor, relying on a provider that implements the [Sublime](https://github.com/dashkite/sublime) interface for HTTP.

## Features

- Reactive Protocol: Methods return async generators yielding events like cache-hit, retry, authenticate, and normalized status names.
- Write-Through Caching: Optimistically updates the local cache on put and delete operations for immediate HX updates, assuming the put body matches the future get response.
- Collaborative Authentication: Yields an authenticate event, allowing consumers to handle credentials while Altair manages the retry logic.
- Offline Resilience: Automatically handles offline states with backoff retries.

## Installation

```bash
pnpm install @dashkite/altair
```

## Usage

Altair methods return an async generator (reactor). You can either consume the events or simply wait for the final response.

To use Altair, you must configure it with an object that implements the Sublime interfaces. 

```coffeescript
import Altair from "@dashkite/altair"
import Sublime from "@dashkite/sublime"

sublime = Sublime.make [ rulebase ]
HTTP = Altair.make().use sublime
```

### Basic Usage

If you only care about the final response, you can use `yield from`:

```coffeescript
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

### Reactive Usage

Use `yield from` to delegate to the reactor within another generator, or iterate over it to handle lifecycle events.

```coffeescript
# Within another reactor or async generator
response = yield from HTTP.get 
  origin: "https://api.example.com" 
  target: "/greeting"

# Handling specific events
for await event from HTTP.get { origin, target: "/resource" }
  switch event.name
    when "cache-hit"  then console.log "Serving from cache..."
    when "cache-miss" then console.log "Cache miss, fetching from network..."
    when "retry"      then console.log "Retrying request..."
    when "success"    then console.log "Request succeeded!"
```

### Handling Challenges

You can use a coroutine library like `@dashkite/reactive/event-coroutine` to handle specific lifecycle events like authentication challenges:

```coffeescript
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

## Other Resources

- [Reference](docs/reference.md)
- [Recipes](docs/recipes.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing Guide](docs/testing.md)
