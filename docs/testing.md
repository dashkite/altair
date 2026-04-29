# Testing Guide

Altair uses a specialized testing architecture designed to verify the complex, asynchronous event sequences produced by its reactive generators.

## Architecture

The test suite is partitioned into two main groups to ensure reliability and performance:

- **Parallel Scenarios**: The majority of tests (core methods, caching, retries, etc.) run concurrently using `Amen`'s parallel execution capabilities.
- **Sequential Scenarios**: Tests that require exclusive access to shared resources—specifically the global `navigator` state and the test server (for offline mode simulations)—are run one at a time after the parallel suite completes.

### Cross-Platform Execution

Altair is a universal module, and its test suite is designed to run in both Node.js and the browser to ensure consistent behavior across environments.

- **Node.js**: Tests run using the standard `Amen` runner. A global `fetch` implementation (via `undici`) and a mock `navigator` object are provided to simulate the browser environment.
- **Browser**: Tests are executed in a headless Chromium instance using [Mimic](https://github.com/dashkite/mimic). This ensures that Altair correctly handles browser-specific APIs and behaviors (like the Cache API used for write-through caching).

The `test/index.coffee` runner orchestrates both environments, running the Node suite first followed by the browser suite.

### Directory Structure

- `test/index.coffee`: The top-level runner responsible for starting the server and orchestrating the parallel and sequential runs.
- `test/scenarios/`: Contains the individual scenario groups (e.g., `caching.coffee`, `retries.coffee`).
- `test/scenarios/helpers.coffee`: Centralizes shared testing utilities.
- `test/server/`: A dedicated Express server used for simulated network responses.

## Shared Helpers

To maintain a consistent and readable test style, use the utilities provided in `test/scenarios/helpers.coffee`:

- `subtest`: A wrapper around `Amen.test` with a default 1s timeout.
- `advance`: An imperative helper for moving a generator forward. It automatically detects and throws unexpected errors unless explicitly told not to.
- `HTTP`: A pre-configured Altair instance using standard Sublime and SkySublime rules.

## The Imperative Advancement Pattern

Most tests follow an "imperative advancement" pattern to verify the exact sequence of events:

```coffee
# 1. Initiate the request
events = HTTP.get { origin, target: "/status/200" }

# 2. Assert each event in turn
{ done, value } = await advance events
assert.equal "ok", value.name

{ done, value } = await advance events
assert.equal "success", value.name

# 3. Verify completion
{ done } = await advance events
assert done
```

## Adding New Tests

1. **Create a scenario file**: Add a new file in `test/scenarios/`.
2. **Export a function**: The default export should be a function that accepts a `context` (containing `origin`, `Server`, etc.) and returns an array of tests.
3. **Register the scenario**: Add your new scenario to either the `parallel` or `sequential` dictionary in `test/scenarios/index.coffee`.

## Running Tests

Use the standard package manager command:

```bash
npm test
```

This will build the project and execute the top-level runner. Note that if the sequential tests fail or hang, they may leave the test server running; ensure you kill any lingering processes before restarting.
