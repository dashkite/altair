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
