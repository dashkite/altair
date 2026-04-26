import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { collect, tap } from "@dashkite/river"
import EventCoroutine from "@dashkite/reactive/event-coroutine"
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"
import Sublime from "@dashkite/sublime"
import sky from "@dashkite/sky-sublime"
import Altair from "@dashkite/altair"

trace = tap ( event ) ->
  console.log { event }

HTTP = Altair
  .make()
  .use Sublime.make [ sky ]

subtest = ( description, action ) ->
  test description, wait: 1000, action

scenarios = ({ scheme, domain, port }) ->

  origin = "#{ scheme }://#{ domain }:#{ port }"

  "core methods": [

    subtest "get", ->

      events = await HTTP.get { 
        origin
        target: "/status/200" 
      }

      { done, value: { name, scope, response }} = await events.next()
      
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status

      { done, value: { name }} = await events.next()
      assert !done
      assert.equal "success", name

      { done } = await events.next()
      assert done

    subtest "post (created)", ->
      events = await HTTP.post {
        origin
        target: "/status/201"
      }

      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "created", name
      assert.equal "response", scope
      assert.equal 201, response.status
      assert.equal "/status/200/9999", response.headers.get "location"

      { done, value: { name }} = await events.next()
      assert !done
      assert.equal "success", name

      { done } = await events.next()
      assert done

    subtest "put (ok)", ->
      events = await HTTP.put {
        origin
        target: "/status/200"
      }
      
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status

      { done, value: { name }} = await events.next()
      assert !done
      assert.equal "success", name

      { done } = await events.next()
      assert done

    subtest "put (created)", ->
      events = await HTTP.put {
        origin
        target: "/status/201"
      }
      
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "created", name
      assert.equal "response", scope
      assert.equal 201, response.status

      { done, value: { name }} = await events.next()
      assert !done
      assert.equal "success", name

      { done } = await events.next()
      assert done

    subtest "delete (ok)", ->
      events = await HTTP.delete {
        origin
        target: "/status/200"
      }
      
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status

      { done, value: { name }} = await events.next()
      assert !done
      assert.equal "success", name

      { done } = await events.next()
      assert done

    subtest "delete (no-content)", ->
      events = await HTTP.delete {
        origin
        target: "/status/204"
      }
      
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "no-content", name
      assert.equal "response", scope
      assert.equal 204, response.status

      { done, value: { name }} = await events.next()
      assert !done
      assert.equal "success", name

      { done } = await events.next()
      assert done

  ]

  "error-handling": [

    subtest "response errors (404)", ->
      events = await HTTP.get {
        origin
        target: "/status/404"
      }

      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "not-found", name
      assert.equal "response", scope

      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "failure", name
      assert.equal "response", scope

      { done } = await events.next()
      assert done

    subtest "pre-dispatch (request) errors", ->
      events = await HTTP.get {
        origin: "http://unknown"
        target: "/status/200"
      }

      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "error", name
      assert.equal "request", scope

      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "failure", name
      assert.equal "request", scope

      { done } = await events.next()
      assert done
  ]


  "concurrency": [

    subtest "concurrency", ->

      Promise.all do ->

        for i in [ 1..5 ]

          do ( i = i.toString()) ->

            events = await HTTP.get {
              origin
              target: "/status/200/#{ i }"
            }
            
            { done, value: { name, response }} = await events.next()
            assert !done
            assert.equal "ok", name
            assert.equal i, response.content.id

            { done, value: { name }} = await events.next()
            assert !done
            assert.equal "success", name

            { done } = await events.next()
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

      events = await HTTP.get {
        origin
        target: "/authorization"
        authorization: [ "bearer" ]
      }

      # 1. Initial request fails with unauthorized
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "unauthorized", name
      assert.equal "response", scope

      # 2. Generator asks to authenticate
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "authenticate", name
      assert.equal "request", scope
      
      # 3. We provide credentials
      secret = "secret"

      # Resume with 'true' to signal authentication success
      { done, value: { name, scope }} = await events.next true
      assert !done
      assert.equal "retry", name
      assert.equal "request", scope

      # 4. The retry succeeds
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status

      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "success", name
      assert.equal "response", scope

      { done } = await events.next()
      assert done

    subtest "retry exhaustion", ->
      events = await HTTP.get {
        origin
        target: "/always-unauthorized"
        authorization: [ "bearer" ]
      }
      
      # Default limit for Retry.Counter is 3
      for i in [ 1..3 ]

        # Unauthorized attempt
        { done, value: { name, scope }} = await events.next()
        assert !done
        assert.equal "unauthorized", name
        assert.equal "response", scope

        # Request to authenticate
        { done, value: { name, scope }} = await events.next()
        assert !done
        assert.equal "authenticate", name
        assert.equal "request", scope

        # Resume with true to signal "retry"
        { done, value: { name, scope }} = await events.next true
        assert !done
        assert.equal "retry", name
        assert.equal "request", scope

      # 4th attempt: it should NOT retry anymore
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "unauthorized", name
      assert.equal "response", scope

      # It should then yield failure
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "failure", name
      assert.equal "response", scope

      { done } = await events.next()
      assert done

  ]


  "retries": [

    subtest "server error", ->
      events = await HTTP.get {
        origin
        target: "/flakey/server-error"
      }
      
      # 1. First attempt fails (503), yields retry
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "retry", name
      assert.equal "request", scope
      
      # 2. Second attempt succeeds (200)
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status
      
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "success", name
      assert.equal "response", scope

      { done } = await events.next()
      assert done

    subtest "too many requests (429)", ->
      events = await HTTP.get {
        origin
        target: "/too-many-requests/retries"
      }
      
      # 1. First attempt fails (429), yields retry
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "retry", name
      assert.equal "request", scope
      
      # 2. Second attempt succeeds (200)
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status
      
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "success", name
      assert.equal "response", scope

      { done } = await events.next()
      assert done

    subtest "gateway timeout (504)", ->
      events = await HTTP.get {
        origin
        target: "/gateway-timeout/retries"
      }
      
      # 1. First attempt fails (504), yields retry
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "retry", name
      assert.equal "request", scope
      
      # 2. Second attempt succeeds (200)
      { done, value: { name, scope, response }} = await events.next()
      assert !done
      assert.equal "ok", name
      assert.equal "response", scope
      assert.equal 200, response.status
      
      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "success", name
      assert.equal "response", scope

      { done } = await events.next()
      assert done
  ]

export default scenarios
