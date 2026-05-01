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

    # 1. Cache miss, initial failure, and challenge
    await advance events, [ "cache-miss", "unauthorized", "authenticate" ]
    
    # 3. We provide credentials
    secret = "secret"

    # Resume with 'true' to signal authentication success
    await advance events, name: "retry", next: true

    # 4. The retry succeeds
    { value: { response }} = await advance events, "ok"
    assert.equal 200, response.status

    await advance events, [ "success", "done" ]

  subtest "retry exhaustion", ->
    events = HTTP.get {
      origin
      target: "/always-unauthorized"
      authorization: [ "bearer" ]
    }
    
    # Default limit for Retry.Counter is 3
    for i in [ 1..3 ]

      if i == 1
        await advance events, "cache-miss"

      # Unauthorized attempt, challenge, and resume
      await advance events, [ "unauthorized", "authenticate", { name: "retry", next: true }]

    # 4th attempt: it should NOT retry anymore
    await advance events, [ "unauthorized", "failure", "done" ]

]
