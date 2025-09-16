import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import EventCoroutine from "@dashkite/reactive/event-coroutine"

import HTTP from "../../src"

import "./authorizers"

window.__test = ->

  test "Altair", [

    test "vanilla HTTP", [

      test "get", [

        # TODO add support for generator functions to amen
        test "ok", ->

          response = await yield from HTTP.get 
            origin: "http://localhost:3001", 
            target: "/status/200"

          assert.equal 200,
            response.status

        test "JSON", ->

          response = await yield from HTTP.get 
            origin: "http://localhost:3001", 
            target: "/json"
            headers:
              accept: "application/json"

          assert.equal "json", 
            ( response.headers.get "content-type" ).subtype

          assert.equal "Yours Truly",
            response.content.greeting?.from

          assert.equal 200,
            response.status

      ]

      test "put", [

        test "create", ->

          response = await yield from HTTP.put 
            origin: "http://localhost:3001", 
            target: "/status/201"
            content: "hello, world"

          assert.equal 201,
            response.status

        test "update", ->

          response = await yield from HTTP.put 
            origin: "http://localhost:3001", 
            target: "/status/200"
            content: "hello, world"

          assert.equal 200,
            response.status

      ]

      test "delete", [

        test "ok", ->
          response = await yield from HTTP.delete 
            origin: "http://localhost:3001", 
            target: "/delete"

          assert.equal 200,
            response.status

      ]

      test "post", [

        test "post", ->
          response = await yield from HTTP.post 
            origin: "http://localhost:3001", 
            target: "/post"
            content: "hello, world"
            headers:
              accept: "application/json"

          assert.equal 200,
            response.status

      ]

    ]

    test "authorization", [

      test "with hint", ->

        response = await yield from HTTP.get
          origin: "http://localhost:3001", 
          target: "/authorized"
          authorization: [ "foo" ]
          headers:
            accept: "application/json"

        assert.equal 200, response.status

      test "negotiated", ->

        response = await EventCoroutine
          .make HTTP.get
            origin: "http://localhost:3001", 
            target: "/authorized"
            headers:
              accept: "application/json"
          .when "authenticate", -> true
          .start()

        assert.equal 200, response.status

      test "negotiation failure", ->

        response = await EventCoroutine
          .make HTTP.get
            origin: "http://localhost:3001", 
            target: "/authorized"
            headers:
              accept: "application/json"
          .when "authenticate", -> false
          .start()

        assert.equal 401, response.status

    ]

    test "retries", [

      test "service unavailable", ( counter = 0 ) ->

        response = await EventCoroutine
          .make HTTP.get
            origin: "http://localhost:3001", 
            target: "/status/503"
            headers:
              accept: "application/json"
          .when "retry", ({ request }) ->
            request.update ( input ) ->
              if counter++ == 3
                input.target = "/status/200"
              input
          .start()

        assert.equal 3, counter

      test "gateway timeout", ( counter = 0 ) ->

        response = await EventCoroutine
          .make HTTP.get
            origin: "http://localhost:3001", 
            target: "/status/504"
            headers:
              accept: "application/json"
          .when "retry", ({ request }) ->
            request.update ( input ) ->
              if counter++ == 3
                input.target = "/status/200"
              input
          .start()

        assert.equal 3, counter

    ]

  ]
