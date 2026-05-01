import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"
import Events from "./events"

export default ({ origin }) -> [

  subtest "malformed request", ->
    # Authorization must be an array.
    # The error is thrown inside the generator during the 
    # initial normalization (await request.get()).
    events = HTTP.get {
      origin
      target: "/status/200"
      authorization: "not an array"
    }

    # This should yield the normalized error event and failure
    await advance events, [
      { throw: false, Events[ "ill-formed-authorization" ]... }
      { throw: false, Events[ "request-failure" ]... }
      "done"
    ]

  subtest "malformed response content", ->
    events = HTTP.get {
      origin
      target: "/malformed-json"
    }

    # 0. Cache miss
    await advance events, "cache-miss"

    # 1. Yields initial ok
    { value: { response }} = await advance events, "ok"

    # 2. Accessing content forces parsing
    try
      content = response.content
      assert.fail "Should have thrown SyntaxError"
    catch error
      assert error.message.includes "JSON"

    # Note: Altair doesn't catch errors from the value object itself 
    # once it's been yielded to the client. This test verifies that
    # malformed content is indeed detectable.

    await advance events, [ "success", "done" ]

]
