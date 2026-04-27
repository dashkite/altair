# Technical Notes

### Write-Through Caching Strategy

Altair implements an optimistic write-through cache to improve perceived performance and support immediate application updates.

- **Populating**: When a `put` request is initiated, Altair automatically creates a synthetic `get` entry in the local `altair` cache store. This entry uses the request's content as its body and is marked with an `ok` status.
- **Invalidating**: When a `delete` request is initiated, Altair immediately removes the corresponding `get` entry from the cache.
- **Cleanup**: Once a `put` or `delete` request lifecycle ends (either through success or fatal failure), Altair removes any synthetic entries to ensure the application returns to standard HTTP caching semantics provided by the server.

### Reactive Authentication Protocol

Altair uses a collaborative, reactive protocol for handling authentication challenges, allowing it to remain protocol-agnostic while supporting complex auth flows.

- **Challenge Detection**: When Altair receives a `401 Unauthorized` response, it yields an `unauthorized` event followed immediately by an `authenticate` event.
- **Challenge Payload**: The `authenticate` event contains a `challenges` property, which is a list of authentication schemes and parameters provided by the server's `WWW-Authenticate` header.
- **Consumer Responsibility**: The consumer of the reactor is responsible for handling the `authenticate` event. This typically involves updating the `@dashkite/registry` with appropriate credentials or authorizers.
- **Retry Signal**: After handling the challenge, the consumer resumes the generator by passing `true`.
- **Rebuilding the Request**: Upon receiving `true`, Altair rebuilds the request. It uses [Sublime](https://github.com/dashkite/sublime) to automatically find the correct authorizer in the `Registry` (matching the server's challenges) and inject the required headers into the new request attempt.
- **Retry Attempt**: Altair yields a `retry` event and dispatches the newly authorized request.

This protocol ensures that Altair never needs to "know" about specific tokens or passwords; it simply identifies the need for authorization and provides the hook for the application to fulfill it.

### Offline Resilience

Altair is designed to be resilient in intermittent network environments.

- **Detection**: Altair monitors `globalThis.navigator.onLine`. 
- **Backoff**: If a network request fails while the browser is offline, Altair enters a retry loop using the `Retry.Backoff` strategy. It will continue to yield `retry` events and wait between attempts.
- **Resumption**: The loop continues until the network is restored, at which point the request is dispatched again. If the request fails for a reason other than being offline (and retries are exhausted), a fatal `failure` event is yielded.

### Semantic Normalization

Altair uses a consistent normalization process for all event names and status descriptions.

- **Hyphenation**: All event names are converted to lowercase and spaces are replaced with hyphens (e.g., `not found` becomes `not-found`).
- **Error Mapping**: Errors identified by Sublime (prefixed with `sublime: `) are automatically translated into hyphenated protocol events (e.g., `sublime: invalid url` becomes `invalid-url`).
- **Scope**: Events are explicitly scoped as either `request` (pre-dispatch or retry-related) or `response` (post-dispatch results).
