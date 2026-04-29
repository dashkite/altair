import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"

export default ({ origin }) -> [

  subtest "response errors (404)", ->
    events = HTTP.get {
      origin
      target: "/status/404"
    }

    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "not-found", name
    assert.equal "response", scope

    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "failure", name
    assert.equal "response", scope

    { done } = await advance events
    assert done

  subtest "yield from (server error)", ->
    response = yield from HTTP.get { origin, target: "/status/404" }
    assert response?
    assert.equal 404, response.status
    await return

  subtest "yield from (pre-dispatch error)", ->
    response = yield from HTTP.get { origin: "http://unknown" }
    assert !response?
    await return

  subtest "pre-dispatch (request) errors", ->

    events = HTTP.get {
      origin: "http://unknown"
      target: "/status/200"
    }

    { done, value: { name, scope }} = 
      await advance events, throw: false
    assert !done
    assert.equal "error", name
    assert.equal "request", scope

    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "failure", name
    assert.equal "request", scope

    { done } = await advance events
    assert done

]
