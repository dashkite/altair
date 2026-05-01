import assert from "@dashkite/assert"
import { HTTP, subtest, advance, trace } from "./helpers"

export default ({ origin }) -> [

  subtest "get", ->

    events = HTTP.get { 
      origin
      target: "/status/200" 
    }

    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status

    await advance events, [ "success", "done" ]

  subtest "post (created)", ->
    events = HTTP.post {
      origin
      target: "/status/201"
    }

    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "created"
    assert.equal 201, response.status
    assert.equal "/status/200/9999", response.headers.get "location"

    await advance events, [ "success", "done" ]

  subtest "put (ok)", ->
    events = HTTP.put {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status

    await advance events, [ "success", "done" ]

  subtest "put (created)", ->
    events = HTTP.put {
      origin
      target: "/status/201"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "created"
    assert.equal 201, response.status

    await advance events, [ "success", "done" ]

  subtest "delete (ok)", ->
    events = HTTP.delete {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status

    await advance events, [ "success", "done" ]

  subtest "delete (no-content)", ->
    events = HTTP.delete {
      origin
      target: "/status/204"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "no-content"
    assert.equal 204, response.status

    await advance events, [ "success", "done" ]

  subtest "patch", ->
    events = HTTP.patch {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status

    await advance events, [ "success", "done" ]

  subtest "head", ->
    events = HTTP.head {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status

    await advance events, [ "success", "done" ]

  subtest "options", ->
    events = HTTP.options {
      origin
      target: "/status/204"
    }
    
    # Cache miss
    await advance events, "cache-miss"

    { value: { response }} = await advance events, "no-content"
    assert.equal 204, response.status
  
    await advance events, [ "success", "done" ]

  subtest "yield from", ->
    response = yield from HTTP.get { origin, target: "/status/200" }
    assert response?
    assert.equal 200, response.status
    await return

]
