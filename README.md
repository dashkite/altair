# Altair

*Smart, reactive HTTP client*

[![Hippocratic License HL3-CORE](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-CORE&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/core.html)

## Purpose

Altair is a reactive HTTP client built on top of [Sublime](https://github.com/dashkite/sublime). It provides high-level HTTP methods (`get`, `put`, `post`, `delete`) that return a generator (reactor), yielding events for various stages of the HTTP lifecycle, including content negotiation, authentication, and retries.

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
response = await yield from HTTP.get 
  origin: "https://api.example.com", 
  target: "/greeting"

console.log response.content # { hello: "world" } (if JSON)
```

### Reactive Events

Altair yields events that can be handled using `@dashkite/reactive/event-coroutine`.

```coffee
import EventCoroutine from "@dashkite/reactive/event-coroutine"

response = await EventCoroutine
  .make HTTP.get
    origin: "https://api.example.com"
    target: "/authorized"
  .when "authenticate", -> true # Signal that we should retry with authentication
  .start()
```

## Other Resources

- [Reference](docs/reference.md)

## Status

Not suitable for production use. Please report bugs and feature requests via the issue tracker.
