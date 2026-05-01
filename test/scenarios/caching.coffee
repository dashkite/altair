import assert from "@dashkite/assert"
import { sleep } from "@dashkite/joy/time"
import { start } from "@dashkite/river"
import { Address, HTTP, subtest, advance } from "./helpers"


export default ({ origin }) -> [

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

    { value: { response }} = await advance events, "cache-hit"
    assert.equal id, response.content.id

    # cache-hit is followed by the response description and success
    await advance events, [ "ok", "success", "done" ]

    # allow the original PUT to finish
    await pending
    
    # Subsequent GET should NOT hit cache (cleared)
    events = HTTP.get {
      origin
      target: "/delay/200/#{ id }"
    }
    await advance events, "cache-miss"
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

    await advance events, "cache-miss"

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

    # Cache miss
    await advance events, "cache-miss"

    # We might get retries depending on configuration, 
    # so we loop until we get 'failure'
    loop
      { done, value } = await advance events, throw: false
      assert !done
      if value.name == "failure"
        assert.equal "response", value.scope
        # Verify content is still available for recovery
        assert.deepEqual content, value.request.content
        break
      
    await advance events, "done"

]
