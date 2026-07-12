# Recipes

## Handling Authentication Challenges

Altair yields an `authenticate` event when the server returns a `401 Unauthorized`. Use an `EventCoroutine` to wait for credentials before signaling a retry.

```coffeescript
import EventCoroutine from "@dashkite/reactive/event-coroutine"

# A reactor for an authorized request
reactor = HTTP.get 
  origin: "https://api.example.com"
  target: "/profile"
  authorization: [ "bearer" ]

response = await EventCoroutine
  .make reactor
  .when "authenticate", ->
    # Once credentials are ready in the Registry...
    true # Signal that Altair should retry
  .start()
```

## Providing Credentials for Authentication

To fulfill an `authenticate` request, provide an authorizer in the `@dashkite/registry` that matches the server's challenge scheme.

```coffeescript
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"

# 1. Create an authorizer registry
authorizers = Sierra.make()

# 2. Add a Bearer authorizer
authorizers.add "bearer",
  matches: ( challenge ) -> true
  get: ( challenge ) -> 
    scheme: "bearer"
    token: "your-secret-token"

# 3. Register it for Sublime/Altair to find
Registry.set "authorizers", authorizers
```

## Handling Expired Credentials

The reactive protocol automatically handles expired tokens. If a previously valid token expires, the server will return another `401 Unauthorized`.

1. Altair yields `authenticate` again.
2. Your `EventCoroutine` captures the event.
3. You refresh the token and update the `Registry`.
4. You pass `true` to the generator.
5. Altair retries with the new token.

## Optimistic HX with Write-Through Caching

Use `put` or `delete` to optimistically update the cache. Subsequent `get` requests for the same resource will yield a `cache-hit` immediately, even if the original update is still in flight.

```coffeescript
# 1. Update the resource (takes some time)
HTTP.put 
  origin: "https://api.example.com"
  target: "/settings"
  content: { theme: "dark" }

# 2. Get the resource immediately after
# This will yield a 'cache-hit' with { theme: "dark" }
events = HTTP.get
  origin: "https://api.example.com"
  target: "/settings"

{ value } = await events.next()
if value.name == "cache-hit"
  console.log "Reflecting update immediately:", value.response.content
```

## Handling Persistent Failures

You can monitor the reactor to detect when a request has completely failed after all retries have been exhausted.

```coffeescript
import { collect } from "@dashkite/river"

# Attempt a request that might fail
events = HTTP.get { origin: "https://flakey.com" }

# Run to completion and collect all events
results = await collect events

# Check for failure
if results.find ( e ) -> e.name == "failure"
  console.error "Request failed after all retries"
```
