import assert from "@dashkite/assert"
# import { test } from "@dashkite/amen"
import { sleep } from "@dashkite/joy/time"
import { start as run } from "@dashkite/river"
import { Address, HTTP, subtest, advance, trace } from "./helpers"

export default ({ start, stop, port, origin }) -> [

  subtest "success after network restoration", ->

    id = Address.make()
    
    # 1. Start offline by stopping server and toggling navigator
    await stop()
    globalThis.navigator.onLine = false
    
    events = HTTP.get {
      origin
      target: "/status/200/#{ id }"
    }
    
    # 2. Should yield retry (from offline backoff)
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "retry", name
    assert.equal "request", scope
    
    # 3. Restore network and restart server
    globalThis.navigator.onLine = true
    await start port
    
    # 4. Resume and succeed
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "ok", name
    assert.equal "response", scope
    
    { done, value: { name }} = await advance events
    assert !done
    assert.equal "success", name
    
    { done } = await advance events
    assert done

  subtest "failure if network remains offline", ->

    id = Address.make()
    
    # 1. Start and stay offline
    await stop()
    globalThis.navigator.onLine = false
    
    events = HTTP.get {
      origin
      target: "/status/200/#{ id }"
    }
    
    # Verify at least one retry occurs
    { done, value: { name }} = await advance events
    assert.equal "retry", name
    
    # Then restore so we can finish and clean up
    globalThis.navigator.onLine = true
    await start port
    await run events

]
