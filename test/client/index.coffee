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

          assert.deepEqual ( response.headers.get "content-type" ),
            type: "application"
            subtype: "json"

          assert.equal "Yours Truly",
            response.content.slideshow?.author

          assert.equal 200,
            response.status

      ]

      test "put", [

        test "created", ->

          response = await yield from HTTP.put 
            origin: "https://httpbin.org", 
            target: "/status/201"

          assert.equal 201,
            response.status

      ]

    ]

  ]
