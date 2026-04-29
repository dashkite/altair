import assert from "@dashkite/assert"
# import { test } from "@dashkite/amen"
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
    
    # 2. Should yield retry (from offline backoff)
    { done, value: { name, scope }} = await advance events
    assert !done
    assert.equal "retry", name
    assert.equal "request", scope
    
    # 3. Restore network and restart server
    await start()
    
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

  await subtest "failure if network remains offline", ->

    id = Address.make()
    
    # 1. Start and stay offline
    await stop()
    
    events = HTTP.get {
      origin
      target: "/status/200/#{ id }"
    }
    
    # 2. We get repeated retries...
    
    # stop at 3 because otw test will time out due to backoff
    for i in [1..3]
      { done, value: { name }} = await advance events
      assert.equal "retry", name
    
    # Then restore so we can finish and clean up
    await start()

    run events

]
