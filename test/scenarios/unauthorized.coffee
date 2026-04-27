import assert from "@dashkite/assert"
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"
import { HTTP, subtest, advance } from "./helpers"

export default ({ origin }) -> [

  subtest "unauthorized", ->
    
    secret = undefined

    authorizers = Sierra.make()
    authorizers.add "bearer",
      matches: -> secret?
      get: -> 
        if secret?
          scheme: "bearer"
          token: secret
  
    Registry.set "authorizers", authorizers

    events = HTTP.get {
      origin
      target: "/authorization"
      authorization: [ "bearer" ]
    }

    # 1. Initial request fails with unauthorized
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "unauthorized", name
    assert.equal "response", scope

    # 2. Generator asks to authenticate
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "authenticate", name
    assert.equal "request", scope
    
    # 3. We provide credentials
    secret = "secret"

    # Resume with 'true' to signal authentication success
    { done, value: { name, scope }} = await advance events, next: true
    assert !done
    assert.equal "retry", name
    assert.equal "request", scope

    # 4. The retry succeeds
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

  subtest "retry exhaustion", ->
    events = HTTP.get {
      origin
      target: "/always-unauthorized"
      authorization: [ "bearer" ]
    }
    
    # Default limit for Retry.Counter is 3
    for i in [ 1..3 ]

      # Unauthorized attempt
      { done, value: { name, scope }} = await advance events
      assert !done
      assert.equal "unauthorized", name
      assert.equal "response", scope

      # Request to authenticate
      { done, value: { name, scope }} = await advance events
      assert !done
      assert.equal "authenticate", name
      assert.equal "request", scope

      # Resume with true to signal "retry"
      { done, value: { name, scope }} = await advance events, next: true
      assert !done
      assert.equal "retry", name
      assert.equal "request", scope

    # 4th attempt: it should NOT retry anymore
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "unauthorized", name
    assert.equal "response", scope

    # It should then yield failure
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "failure", name
    assert.equal "response", scope

    { done } = await advance events
    assert done

]
