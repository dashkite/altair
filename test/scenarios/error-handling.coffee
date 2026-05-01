import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"
import Events from "./events"

export default ({ origin }) -> [

  subtest "response errors (404)", ->
    events = HTTP.get {
      origin
      target: "/status/404"
    }

    # Cache miss
    await advance events, [ "cache-miss", "not-found", "failure", "done" ]

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

    # Cache miss
    await advance events, [
      { throw: false, Events[ "cache-miss" ]... }
      { throw: false, Events[ "error" ]... }
      "request-failure", "done"
    ]

]
