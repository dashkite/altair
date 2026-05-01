import assert from "@dashkite/assert"
import { HTTP, subtest, advance } from "./helpers"

export default ({ origin }) -> [

  subtest "isolation", ->

    Promise.all do ->

      for i in [ 1..5 ]

        do ( i = i.toString()) ->

          events = HTTP.get {
            origin
            target: "/status/200/#{ i }"
          }
          
          # Cache miss
          await advance events, "cache-miss"

          { value: { response }} = await advance events, "ok"
          assert.equal i, response.content.id

          await advance events, [ "success", "done" ]
]
