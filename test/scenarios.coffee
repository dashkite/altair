import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { sleep } from "@dashkite/joy/time"
import { tap, start } from "@dashkite/river"
import EventCoroutine from "@dashkite/reactive/event-coroutine"
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"
import Sublime from "@dashkite/sublime"
import sky from "@dashkite/sky-sublime"
import Altair from "@dashkite/altair"

Address =
  make: ->
    Math
      .random()
      .toString 36
      .slice 2

trace = tap ( event ) ->
  # console.log { event }
  event

HTTP = Altair
  .make()
  .use Sublime.make [ sky ]

subtest = ( description, action ) ->
  test description, wait: 1000, action

advance = ( events, options = { throw: true }) ->
  { done, value } = await events.next options.next
  if value?.error? && options.throw
    throw value.error
  { done, value }

scenarios = ({ scheme, domain, port }) ->

  origin = "#{ scheme }://#{ domain }:#{ port }"

  "core methods": [

    subtest "get", ->

      events = HTTP.get { 
        origin
        target: "/status/200" 
      }

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

  ]

  "error-handling": [

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


  "concurrency": [

    subtest "isolation", ->

      Promise.all do ->

        for i in [ 1..5 ]

          do ( i = i.toString()) ->

            events = HTTP.get {
              origin
              target: "/status/200/#{ i }"
            }
            
            { done, value: { name, response }} = await advance events
            assert !done
            assert.equal "ok", name
            assert.equal i, response.content.id

            { done, value: { name }} = await advance events
            assert !done
            assert.equal "success", name

            { done } = await advance events
            assert done
  ]

  "unauthorized": [

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


  "retries": [

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


  "caching": [

    subtest "write-through hit", ->

      id = Address.make()
      
      pending = start HTTP.put {
        origin
        target: "/delay/200/#{ id }"
        content: { id }
      }

      # wait for writethru
      await sleep 50

      # GET should hit cache
      events = HTTP.get {
        origin
        target: "/delay/200/#{ id }"
      }

      { done, value: { name, scope, response }} = await advance events
      assert !done
      assert.equal "cache-hit", name
      assert.equal "request", scope
      assert.equal id, response.content.id

      # cache-hit is followed by the response description and success
      await advance events # ok/description
      await advance events # success
      { done } = await advance events
      assert done

      # allow the original PUT to finish
      await pending
      
      # Subsequent GET should NOT hit cache (cleared)
      events = HTTP.get {
        origin
        target: "/delay/200/#{ id }"
      }
      { done, value: { name }} = await advance events
      assert !done
      assert.notEqual "cache-hit", name
      await start events

    subtest "delete clears cache", ->

      id = Address.make()
      
      # 1. Prime the cache with a PUT
      await start HTTP.put {
        origin
        target: "/delay/0/#{ id }"
        content: { id }
      }

      # 2. Start a slow DELETE
      pending = start HTTP.delete {
        origin
        target: "/delay/200/#{ id }"
      }

      # wait for writethru (which should delete the entry)
      await sleep 50

      # 3. GET should NOT hit cache
      events = HTTP.get {
        origin
        target: "/delay/200/#{ id }"
      }

      { done, value: { name }} = await advance events
      assert !done
      assert.notEqual "cache-hit", name

      # finish the GET and the pending DELETE
      Promise.all [
        start events
        pending
      ]

    subtest "data recovery on failure", ->

      id = Address.make()
      content = { id, data: "important" }

      # 1. Failing PUT (500)
      events = HTTP.put {
        origin
        target: "/status/500/#{ id }"
        content: content
      }

      # We might get retries depending on configuration, 
      # so we loop until we get 'failure'
      loop
        { done, value: { name, scope, request }} = 
          await advance events, throw: false
        assert !done
        if name == "failure"
          assert.equal "response", scope
          # Verify content is still available for recovery
          request = await request.get()
          assert.deepEqual content, request.content
          break
        
      { done } = await advance events
      assert done

  ]

export default scenarios
