# Technical Notes

## System Architecture

### The Platonic HTTP Interface

Altair relies on [Sublime](https://github.com/dashkite/sublime), which provides a platonic representation of HTTP requests and responses. By defining requests and responses as simple data structures, Altair decouples the abstract definition of a network operation from the concrete execution layer. This enables metaprogramming and rules-based transformation of HTTP traffic before it hits the network.

### Functional Composition

Underneath the hood, Altair utilizes [Joy](https://github.com/dashkite/joy) for functional metaprogramming and composition. By combining the simplicity of Lodash with the functional pipeline concepts of Rambda, Joy allows Altair to express complex transformations, such as semantic normalization of event names, without resorting to imperative state mutation.

### Generators as Coroutines

Rather than treating a network request as a single [Promise](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise) that eventually resolves or rejects, Altair models the HTTP request-response lifecycle as a stream of discrete semantic events. This is achieved using asynchronous generators, which function as [Coroutines](https://en.wikipedia.org/wiki/Coroutine).

This reactive architecture aligns with [Reactive Programming](https://en.wikipedia.org/wiki/Reactive_programming) paradigms, allowing the consumer to pause execution, yield control back to the caller (such as `EventCoroutine` from the `@dashkite/reactive` library), and handle intermediate lifecycle events like retries or cache hits before the final response is processed.

## Network Strategies

### Optimistic Write-Through Caching

Altair implements a [write-through cache](https://en.wikipedia.org/wiki/Cache_(computing)#Writing_policies) to improve perceived performance and enable immediate interface updates.

When a `put` request is initiated, Altair automatically provisions a synthetic `get` entry in the local `altair` cache store. This entry uses the request's content payload as its body and is immediately marked with an `ok` status. This strategy assumes that the `put` request's body content mirrors what a subsequent `get` request would return, which strictly aligns with standard [HTTP caching semantics](https://developer.mozilla.org/en-US/docs/Web/HTTP/Caching).

Subsequent `get` requests yield a `cache-hit` if the resource is found in the local cache, reducing perceived latency. Conversely, when a `delete` request is initiated, Altair removes the corresponding `get` entry to prevent serving stale data. Once a `put` or `delete` lifecycle terminates, the synthetic entries are cleaned up, returning control to the standard server-driven caching semantics.

### Offline Detection and Exponential Backoff

Altair is designed to be resilient against intermittent network degradation, such as transitioning between cellular networks or dropping offline entirely.

Altair continuously monitors `globalThis.navigator.onLine` (detailed in [Navigator.onLine](https://developer.mozilla.org/en-US/docs/Web/API/Navigator/onLine)) to detect network availability. When a request fails due to the browser being offline, Altair prevents immediate failure. Instead, it enters a non-blocking retry loop governed by an [exponential backoff](https://en.wikipedia.org/wiki/Exponential_backoff) strategy. It yields `retry` events, waiting between attempts until the network connection is restored, at which point the request is re-dispatched.

### Collaborative, Reactive Authentication Protocol

Altair utilizes a collaborative protocol to handle authentication challenges, avoiding direct management of cryptographic tokens or sensitive authentication credentials.

When Altair receives a [`401 Unauthorized`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401) response, it surfaces an `unauthorized` event followed by an `authenticate` event. The `authenticate` event contains a `challenges` property, representing the parsed authentication schemes from the server's [`WWW-Authenticate`](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/WWW-Authenticate) header.

The consumer intercepts this event, updating the `@dashkite/registry` with appropriate credentials or authorizers. The consumer then resumes the generator by passing `true`. Altair dynamically rebuilds the request, relying on the Sublime interface to locate the matching authorizer in the registry and inject the newly acquired headers into the retry attempt.
