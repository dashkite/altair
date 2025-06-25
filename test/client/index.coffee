import assert from "@dashkite/assert"
import {test, success} from "@dashkite/amen"
import api from "./api"

import HTTP from "../../src/index.js"

window.__test = ->

  window.fetch = ( context ) ->
    switch context
      when "https://acme.org/", "https://acme.org"
        new Response ( json api ),
          status: 200
          "content-type": "application/json"
      else
        new Response "hello Dan", 
          status: 200
          "content-type": "text/plain"

  window.json = ( value ) ->
    JSON.stringify value, null, 2

  test "Altair", [
    test "greeting", ->
      for await event from ( HTTP.get 
                              origin: "https://acme.org", 
                              target: "/test" )
        console.log event.name
        if event.response?
          response = event.response
      assert.equal "hello Dan",
        await response.text()  ]
