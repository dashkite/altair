import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"

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

    # This should yield the normalized error event
    { done, value: { name, scope }} = await advance events, throw: false
    assert !done
    assert.equal "ill-formed-authorization", name
    assert.equal "request", scope

    # The outer catch block now also yields failure
    { done, value: { name, scope }} = await advance events, throw: false
    assert !done
    assert.equal "failure", name
    assert.equal "request", scope

    { done } = await advance events
    assert done

  subtest "malformed response content", ->
    events = HTTP.get {
      origin
      target: "/malformed-json"
    }

    # 1. Yields initial ok
    { done, value: { name, response }} = await advance events
    assert.equal "ok", name

    # 2. Accessing content forces parsing
    try
      content = response.content
      assert.fail "Should have thrown SyntaxError"
    catch error
      assert error.message.includes "JSON"

    # Note: Altair doesn't catch errors from the value object itself 
    # once it's been yielded to the client. This test verifies that
    # malformed content is indeed detectable.
    
    await advance events # success
    { done } = await advance events
    assert done

]
