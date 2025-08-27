import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"

import HTTP from "../../src"

import api from "./api"

window.__test = ->

  test "Altair", [

    test "vanilla HTTP", [

      test "get", [

        # TODO add support for generator functions to amen
        test "ok", ->

          response = await yield from HTTP.get 
            origin: "https://httpbin.org", 
            target: "/status/200"

          assert.equal 200,
            response.status

        test "JSON", ->

          response = await yield from HTTP.get 
            origin: "https://httpbin.org", 
            target: "/json"
            headers:
              accept: "application/json"

          assert.deepEqual ( response.headers.get "content-type" ).data,
            type: "application"
            subtype: "json"

          assert.equal "Yours Truly",
            response.content.slideshow?.author

          assert.equal 200,
            response.status

      ]

      test "put", [

        test "create", ->

          response = await yield from HTTP.put 
            origin: "https://httpbin.org", 
            target: "/status/201"
            content: "hello, world"

          assert.equal 201,
            response.status

        test "update", ->

          response = await yield from HTTP.put 
            origin: "https://httpbin.org", 
            target: "/status/200"
            content: "hello, world"

          assert.equal 200,
            response.status

      ]

      test "delete", [

        test "ok", ->
          response = await yield from HTTP.delete 
            origin: "https://httpbin.org", 
            target: "/delete"

          assert.equal 200,
            response.status

          assert.equal "httpbin.org",
            response.content.headers.Host

      ]

      test "post", [

        test "post", ->
          response = await yield from HTTP.post 
            origin: "https://httpbin.org", 
            target: "/post"
            content: "hello, world"
            headers:
              accept: "application/json"

          assert.equal 200,
            response.status

          assert.equal "httpbin.org",
            response.content.headers.Host

      ]

    ]

  ]
