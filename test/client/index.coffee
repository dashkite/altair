import assert from "@dashkite/assert"
import { test, success } from "@dashkite/amen"
import api from "./api"

import HTTP from "../../src"

window.__test = ->

  test "Altair", [

    test "greeting", ->

      reactor = HTTP.get 
        origin: "https://httpbin.org", 
        target: "/status/200"

      for await event from reactor
        console.log event.name
        if event.response?
          response = event.response

      assert.equal 200,
        response.status

  ]
