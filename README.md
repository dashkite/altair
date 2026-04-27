# Altair

*Smart, reactive HTTP client*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

## Purpose

Altair is a reactive HTTP client built on top of [Sublime](https://github.com/dashkite/sublime). It extends standard HTTP semantics with reactive streams and smart features like write-through caching and retry logic. Altair methods return an async generator (reactor) that yields semantic events for every stage of the HTTP lifecycle.

### Differentiating Features

- **Write-Through Caching**: Optimistically updates the local cache for `put` and `delete` operations, allowing applications to reflect state changes immediately without waiting for network confirmation.
- **Offline Resilience**: Automatically enters a backoff retry loop when the browser is offline, resuming seamlessly once network connectivity is restored.
- **Protocol Normalization**: Translates HTTP status codes and errors into a consistent set of hyphenated protocol events.

## Installation

Use your favorite package manager to install `@dashkite/altair`.

## Usage

```coffee
import Altair from "@dashkite/altair"
import Sublime from "@dashkite/sublime"
import SkySublime from "@dashkite/sky-sublime"

# Configure Altair with Sublime and Sky Sublime rules
HTTP = Altair
  .make()
  .use Sublime.make [ SkySublime ]

# Perform a simple GET request
# The reactor yields status events and finishes with the response
response = await yield from HTTP.get 
  origin: "https://api.example.com" 
  target: "/greeting"

console.log response.content # { hello: "world" } (if JSON)
```

### Handling Events

Use `@dashkite/reactive/event-coroutine` to handle specific lifecycle events like authentication challenges or retries.

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

## Other Resources

- [Reference](docs/reference.md)
- [Recipes](docs/recipes.md)
- [Technical Notes](docs/technical-notes.md)
- [Testing Guide](docs/testing.md)

## Status

Not suitable for production use. Please report bugs and feature requests via the issue tracker.
