import assert from "@dashkite/assert"
import { test } from "@dashkite/amen"
import { sleep } from "@dashkite/joy/time"
import { start as run } from "@dashkite/river"
import { Address, HTTP, subtest, advance, trace } from "./helpers"

export default ({ start, stop, port, origin }) -> [

  await subtest "success after network restoration", ->

    id = Address.make()
    
    # 1. Start offline by stopping server and toggling navigator
    await stop()
    
    events = HTTP.get {
      origin
      target: "/status/200/#{ id }"
    }

    # 0. Cache miss and initial retry
    await advance events, [ "cache-miss", "retry" ]
    
    # 3. Restore network and restart server
    await start()
    
    # 4. Resume and succeed
    await advance events, [ "ok", "success", "done" ]

  await test "failure if network remains offline", wait: 5000, ->

    id = Address.make()
    
    # 1. Start and stay offline
    await stop()
    
    events = HTTP.get {
      origin
      target: "/status/200/#{ id }"
    }
    
    # 0. Cache miss
    await advance events, "cache-miss"

    # 2. We get repeated retries...
    await advance events, [ "retry", "retry", "retry" ]
    
    # Then restore so we can finish and clean up
    await start()

    run events

]
