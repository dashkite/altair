import assert from "@dashkite/assert"
import { HTTP, subtest, advance, trace } from "./helpers"

export default ({ origin }) -> [

  subtest "get", ->

    events = HTTP.get { 
      origin
      target: "/status/200" 
    }

    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "post (created)", ->
    events = HTTP.post {
      origin
      target: "/status/201"
    }

    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "created", name
    assert.equal "response", scope
    assert.equal 201, response.status
    assert.equal "/status/200/9999", response.headers.get "location"

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "put (ok)", ->
    events = HTTP.put {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "put (created)", ->
    events = HTTP.put {
      origin
      target: "/status/201"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "created", name
    assert.equal "response", scope
    assert.equal 201, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "delete (ok)", ->
    events = HTTP.delete {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "delete (no-content)", ->
    events = HTTP.delete {
      origin
      target: "/status/204"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "no-content", name
    assert.equal "response", scope
    assert.equal 204, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "patch", ->
    events = HTTP.patch {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "head", ->
    events = HTTP.head {
      origin
      target: "/status/200"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    assert.equal 200, response.status

    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "options", ->
    events = HTTP.options {
      origin
      target: "/status/204"
    }
    
    # Cache miss
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "cache-miss", name
    assert.equal "request", scope

    { done, value: { name, scope, response }} = await advance events
    assert !done
    assert.equal "no-content", name
    assert.equal "response", scope
    assert.equal 204, response.status
  
    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name

    { done } = await advance events
    assert done

  subtest "yield from", ->
    response = yield from HTTP.get { origin, target: "/status/200" }
    assert response?
    assert.equal 200, response.status
    await return

]
