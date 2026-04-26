import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { collect, tap } from "@dashkite/river"
import EventCoroutine from "@dashkite/reactive/event-coroutine"
import Registry from "@dashkite/registry"
import Sierra from "@dashkite/sierra"
import Sublime from "@dashkite/sublime"
import sky from "@dashkite/sky-sublime"
import Altair from "@dashkite/altair"

# trace = tap ( event ) ->
#   console.log event: event.name

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
        origin: "invalid://"
        target: "/status/200"
      }

      { done, value: { name, scope }} = await events.next()
      assert !done
      assert.equal "error", name
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
      authorizers.add "Bearer",
        matches: -> secret?
        get: -> 
          scheme: "Bearer"
          token: secret
    
      Registry.set "authorizers", authorizers

      events = await HTTP.get {
        origin
        target: "/authorization"
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
  ]


  # "retries": [


  #   subtest "server error", ->

  #     # TODO there's no assertion here?
  #     response = await EventCoroutine
  #       .make HTTP.get {
  #         origin
  #         target: "/flakey"
  #       }
  #       .when "retry", ({ request }) -> request
  #       .when "error", ({ error }) -> throw error
  #       .start()
      
  #     assert.equal 200, response.status
  # ]

export default scenarios