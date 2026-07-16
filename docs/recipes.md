# Recipes

## Initializing an Altair Instance

To begin using Altair, you must initialize an instance and configure it with an HTTP protocol provider. This enables you to issue requests using a specific ruleset.

Altair acts as a reactive wrapper around a foundational HTTP protocol. By instantiating Altair and passing a protocol implementation like `Sublime` to the `use` method, you establish the foundation for your HTTP requests.

```coffeescript
import Altair from "@dashkite/altair"
import Sublime from "@dashkite/sublime"

# create your rulebase here
rulebase = {}

sublime = Sublime.make [ rulebase ]
HTTP = Altair.make().use sublime
```

1. Import the `Altair` library and a compatible protocol provider like `Sublime`.
2. Construct the underlying protocol instance.
3. Call `Altair.make()` to create a new client.
4. Call `.use()` on the client, passing the protocol instance to finalize the configuration.

## Retrieving Data and Checking Metadata

To fetch a resource's content or simply verify its existence without downloading the body, you can issue `get` and `head` requests.

Altair provides methods mapped directly to HTTP verbs. While they return reactive generators, you can delegate them to a coroutine runner to extract just the final response. The `head` method behaves exactly like `get` but ensures the response body is omitted, saving bandwidth when you only need headers.

```coffeescript
import { start } from "@dashkite/river"

# fetch a complete resource
start do ->
  response = yield from HTTP.get 
    origin: "https://api.example.com"
    target: "/users/1"
  console.log response.content

# check if a resource exists
start do ->
  response = yield from HTTP.head
    origin: "https://api.example.com"
    target: "/users/2"
  console.log response.status
```

1. Invoke `get` or `head` with a request specifier.
2. Delegate the resulting generator stream to a consumer (e.g., using `yield from` inside a coroutine runner like `start`).
3. Await the conclusion of the stream.
4. Process the final response or its headers.

## Submitting New Data

To create a new resource where the server determines the final identifier, you should dispatch a `post` request.

Because `post` operations are not strictly idempotent and do not imply a specific cache location, Altair dispatches them directly to the network without populating the local write-through cache.

```coffeescript
import { start } from "@dashkite/river"

start do ->
  response = yield from HTTP.post 
    origin: "https://api.example.com"
    target: "/users"
    content: { name: "Bob" }
  console.log response.content
```

1. Invoke `post` with a specifier containing the payload.
2. Delegate the reactor to a coroutine.
3. Await the conclusion of the stream.
4. Process the server's response.

## Mutating Resources and Optimistic HX

To update or remove an existing resource, you can use `put`, `patch`, or `delete` while taking advantage of local caching for immediate interface updates.

Altair implements a write-through cache strategy. Initiating a `put` or `delete` automatically creates or removes a synthetic entry in the cache. When you immediately fetch that resource, Altair yields a `cache-hit` event, reducing perceived latency. The `patch` method can be used when you only need to partially modify a resource over the network.

```coffeescript
# partially modify a resource over the network
HTTP.patch
  origin: "https://api.example.com"
  target: "/settings"
  content: { status: "active" }

# completely replace a resource and update the local cache
HTTP.put 
  origin: "https://api.example.com"
  target: "/settings"
  content: { theme: "dark" }

# fetch the same resource immediately, hitting the cache
events = HTTP.get
  origin: "https://api.example.com"
  target: "/settings"

{ value } = await events.next()
if value.name == "cache-hit"
  console.log "Cache hit:", value.response.content
```

1. Initiate a `patch` to partially modify data, or a `put` to completely replace it.
2. Initiate a `get` request for the same resource without waiting for the `put` to complete.
3. Pull the first event from the `get` reactor.
4. Verify the event is a `cache-hit` containing the optimistically injected data.

## Interrogating Server Capabilities

To discover what HTTP methods or communication options a server supports for a specific endpoint, you can issue an `options` request.

Altair exposes the `options` method to query the server for supported operations, which is particularly useful for debugging CORS configurations or discovering API features before committing to a larger request.

```coffeescript
import { start } from "@dashkite/river"

start do ->
  response = yield from HTTP.options 
    origin: "https://api.example.com"
    target: "/users"
  
  # inspect the allow header for supported methods
  console.log response.headers.allow
```

1. Invoke `options` with the target specifier.
2. Delegate the reactor to a coroutine.
3. Await the conclusion of the stream.
4. Inspect the returned headers for allowed methods.

## Handling Persistent Failures

To definitively confirm a request has failed after exhausting all network retries, you must monitor the reactor for a terminal failure event.

Because Altair yields discrete events for every state change, you can collect the entire sequence and search for the terminal `failure` event to confirm the request could not be completed.

```coffeescript
import { collect } from "@dashkite/river"

events = HTTP.get { origin: "https://flakey.com" }

results = await collect events

if results.find ( e ) -> e.name == "failure"
  console.error "Request failed after all retries"
```

1. Initiate the HTTP request.
2. Collect the entire event stream into a list.
3. Search the collected events for an object where `name` is `"failure"`.
4. Handle the unrecoverable error accordingly.

## Orchestrating Authentication Challenges

To orchestrate complex authentication flows, you can pause the reactor when it yields an authentication challenge, fetch credentials, and then resume the request.

When a server returns a `401 Unauthorized`, Altair pauses and yields an `authenticate` event. Using an event coroutine, you can intercept this specific event, asynchronously gather the required credentials, and signal Altair to rebuild the request and retry.

```coffeescript
import EventCoroutine from "@dashkite/reactive/event-coroutine"
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"

# configure authorizer
authorizers = Sierra.make()
authorizers.add "bearer",
  matches: -> true
  get: -> { scheme: "bearer", token: "secret" }

Registry.set "authorizers", authorizers

# initiate authorized request
reactor = HTTP.get 
  origin: "https://api.example.com"
  target: "/profile"
  authorization: [ "bearer" ]

response = await EventCoroutine
  .make reactor
  .when "authenticate", ->
    # credentials are now ready in the registry
    true
  .start()
```

1. Configure an authorizer matching the server's expected challenge scheme and store it in the registry.
2. Initiate the request with an `authorization` array indicating the preferred scheme.
3. Wrap the reactor in an `EventCoroutine`.
4. Intercept the `authenticate` event.
5. Return `true` to signal that the registry holds valid credentials, instructing Altair to inject them and retry.

## Orchestrating Sky API Authorization

When interacting with a Sky API, you can orchestrate complex authorization flows using a combination of Altair, Sky Sublime, and Sierra. 

Sky APIs often require advanced, compound credentials. While Altair manages the reactive retry flow and `sky-sublime` resolves natural resource names (like `"subscriber profile"`) and challenge negotiation, `sierra` manages the secure generation of compound credential payloads using JSON64 encoding under the `credentials` scheme.

```coffeescript
import EventCoroutine from "@dashkite/reactive/event-coroutine"
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"
import JSON64 from "@dashkite/json64"

# 1. Configure authorizer for compound Sky API credentials
authorizers = Sierra.make()
authorizers.add "credentials",
  matches: ( challenge ) -> challenge.scheme == "credentials"
  get: -> 
    payload = [ { scheme: "bearer", token: "secret" } ]
    { scheme: "credentials", token: JSON64.stringify payload }

Registry.set "authorizers", authorizers

# 2. Initiate request using a colloquial Sky resource specifier
# (assuming HTTP is configured with sky-sublime)
reactor = HTTP.get 
  resource:
    origin: "https://api.example.com"
    name: "subscriber profile"
  authorization: [
    { challenge: { scheme: "credentials" } }
  ]

# 3. Intercept challenge to retry when ready
response = await EventCoroutine
  .make reactor
  .when "authenticate", ->
    # credentials are now ready in the registry
    true
  .start()
```

1. Configure a Sierra authorizer to construct a compound payload stringified via `JSON64` under the `credentials` scheme.
2. Store the authorizer in the registry.
3. Initiate the request using a colloquial `resource` object (with natural whitespace names) and an `authorization` specifier recognized by Sky Sublime.
4. Wrap the reactor in an `EventCoroutine` to intercept the `authenticate` event and signal retries once credentials are in place.
