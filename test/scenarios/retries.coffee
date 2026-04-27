import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"

export default ({ origin }) -> [

  subtest "server error", ->
    events = HTTP.get {
      origin
      target: "/flakey/server-error"
    }
    
    # 1. First attempt fails (503), yields retry
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "retry", name
    assert.equal "request", scope
    
    # 2. Second attempt succeeds (200)
    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status
    
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "success", name
    assert.equal "response", scope

    { done } = await advance events
    assert done

  subtest "too many requests (429)", ->
    events = HTTP.get {
      origin
      target: "/too-many-requests/retries"
    }
    
    # 1. First attempt fails (429), yields retry
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "retry", name
    assert.equal "request", scope
    
    # 2. Second attempt succeeds (200)
    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status
    
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "success", name
    assert.equal "response", scope

    { done } = await advance events
    assert done

  subtest "gateway timeout (504)", ->
    events = HTTP.get {
      origin
      target: "/gateway-timeout/retries"
    }
    
    # 1. First attempt fails (504), yields retry
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "retry", name
    assert.equal "request", scope
    
    # 2. Second attempt succeeds (200)
    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status
    
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "success", name
    assert.equal "response", scope

    { done } = await advance events
    assert done
]
